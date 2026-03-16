import Apollo
@testable import Castor
import Domain
import SwiftProtobuf
import XCTest

final class PrismDIDPublicKeyTests: XCTestCase {
    var seed: Seed!
    var privateKey: PrivateKey!
    var apollo: Apollo!

    override func setUp() async throws {
        apollo = ApolloImpl()
        seed = apollo.createRandomSeed().seed
        privateKey = try apollo.createPrivateKey(parameters: [
            KeyProperties.type.rawValue: "EC",
            KeyProperties.curve.rawValue: KnownKeyCurves.secp256k1.rawValue,
            KeyProperties.seed.rawValue: seed.value.base64Encoded(),
            KeyProperties.derivationPath.rawValue: DerivationPath().keyPathString()
        ])
    }

    func testFromProto() throws {
        let publicKey = PrismDIDPublicKey(
            apollo: apollo,
            id: PrismDIDPublicKey.Usage.masterKey.id(index: 0),
            curve: "secp256k1",
            usage: .masterKey,
            keyData: privateKey.publicKey()
        )

        let protoData = try publicKey.toProto().serializedData()
        let proto = try Io_Iohk_Atala_Prism_Protos_PublicKey(serializedData: protoData)
        let parsedPublicKey = try PrismDIDPublicKey(apollo: apollo, proto: proto)
        XCTAssertEqual(parsedPublicKey.id, "master")
        XCTAssertEqual(parsedPublicKey.keyData.raw, publicKey.keyData.raw)
        XCTAssertEqual(parsedPublicKey.usage, publicKey.usage)
    }

    func testMasterKeyIdHasNoIndex() {
        // Master key ID should be "master" (no index suffix) per spec normalization
        let masterKeyId = PrismDIDPublicKey.Usage.masterKey.id(index: 0)
        XCTAssertEqual(masterKeyId, "master")
        // Master key ID should be the same regardless of the index parameter
        let masterKeyId1 = PrismDIDPublicKey.Usage.masterKey.id(index: 1)
        XCTAssertEqual(masterKeyId1, "master")
    }

    func testOtherKeyTypesUseIndexedId() {
        XCTAssertEqual(PrismDIDPublicKey.Usage.issuingKey.id(index: 0), "issuing0")
        XCTAssertEqual(PrismDIDPublicKey.Usage.issuingKey.id(index: 1), "issuing1")
        XCTAssertEqual(PrismDIDPublicKey.Usage.authenticationKey.id(index: 0), "authentication0")
    }

    func testSecp256k1ToProtoUsesCompressedECKeyData() throws {
        let publicKey = PrismDIDPublicKey(
            apollo: apollo,
            id: PrismDIDPublicKey.Usage.masterKey.id(index: 0),
            curve: "secp256k1",
            usage: .masterKey,
            keyData: privateKey.publicKey()
        )

        let proto = try publicKey.toProto()
        // Verify it uses compressedEcKeyData, not ecKeyData
        switch proto.keyData {
        case .compressedEcKeyData(let compressed):
            XCTAssertEqual(compressed.curve, "secp256k1")
            XCTAssertFalse(compressed.data.isEmpty)
        default:
            XCTFail("Expected compressedEcKeyData for secp256k1, got \(proto.keyData)")
        }
    }

    func testSpecTestVectorRawSeedProducesExpectedDID() throws {
        // Spec test vector from:
        // https://github.com/input-output-hk/prism-did-method-spec/blob/main/extensions/deterministic-prism-did-generation-proposal.md#examples--test-vector
        let specSeedHex = "3b32a5049f2b4e3af31ec5c1ae75fada1ad2eb8be5accf56ada343ad89eeb083208e538b3b97836e3bd7048c131421bf5bea9e3a1d25812a2d831e2bab89e058"
        var specSeedData = Data()
        var hexIndex = specSeedHex.startIndex
        while hexIndex < specSeedHex.endIndex {
            let nextIndex = specSeedHex.index(hexIndex, offsetBy: 2)
            if let byte = UInt8(specSeedHex[hexIndex..<nextIndex], radix: 16) {
                specSeedData.append(byte)
            }
            hexIndex = nextIndex
        }

        // Derive master key at m/29'/29'/0'/1'/0'
        let derivationPath = DerivationPath(axis: [
            .hardened(29), .hardened(29), .hardened(0), .hardened(1), .hardened(0)
        ])

        let masterPrivateKey = try apollo.createPrivateKey(parameters: [
            KeyProperties.type.rawValue: "EC",
            KeyProperties.curve.rawValue: KnownKeyCurves.secp256k1.rawValue,
            KeyProperties.seed.rawValue: specSeedData.base64Encoded(),
            KeyProperties.derivationPath.rawValue: derivationPath.keyPathString()
        ])

        // Verify the compressed public key matches the spec test vector
        guard let compressedB64 = masterPrivateKey.publicKey().getProperty(.compressedRaw),
              let compressedData = Data(base64Encoded: compressedB64) else {
            XCTFail("Could not get compressed public key")
            return
        }
        let compressedPubKeyHex = compressedData.map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(compressedPubKeyHex, "023f7c75c9e5fba08fea1640d6faa3f8dc0151261d2b56026d46ddcbe1fc5a5bbb")

        // Create DID via Castor — master-key-only CreateDID
        let castor = CastorImpl(apollo: apollo)
        let did = try castor.createPrismDID(masterPublicKey: masterPrivateKey.publicKey(), services: [])

        // Extract canonical DID (short-form: did:prism:<hash>)
        let parts = did.string.split(separator: ":")
        let canonicalDID = "\(parts[0]):\(parts[1]):\(parts[2])"

        // Verify the canonical DID matches the spec test vector exactly
        let expectedCanonicalDID = "did:prism:35fbaf7f8a68e927feb89dc897f4edc24ca8d7510261829e4834d931e947e6ca"
        XCTAssertEqual(canonicalDID, expectedCanonicalDID)

        // Verify determinism: same key → same DID
        let did2 = try castor.createPrismDID(masterPublicKey: masterPrivateKey.publicKey(), services: [])
        XCTAssertEqual(did.string, did2.string)
    }

    func testBackwardCompatParseECKeyData() throws {
        // Verify that parsing a proto with ECKeyData (old format) still works
        var protoEC = Io_Iohk_Atala_Prism_Protos_ECKeyData()
        guard
            let pointXStr = privateKey.publicKey().getProperty(.curvePointX),
            let pointYStr = privateKey.publicKey().getProperty(.curvePointY),
            let pointX = Data(base64URLEncoded: pointXStr),
            let pointY = Data(base64URLEncoded: pointYStr)
        else {
            XCTFail("Could not get curve points from public key")
            return
        }
        protoEC.x = pointX
        protoEC.y = pointY
        protoEC.curve = "secp256k1"

        var protoKey = Io_Iohk_Atala_Prism_Protos_PublicKey()
        protoKey.id = "master0"
        protoKey.usage = .masterKey
        protoKey.keyData = .ecKeyData(protoEC)

        // Should parse without error (backward compat)
        let parsedKey = try PrismDIDPublicKey(apollo: apollo, proto: protoKey)
        XCTAssertEqual(parsedKey.id, "master0")
        XCTAssertEqual(parsedKey.usage, .masterKey)
        XCTAssertFalse(parsedKey.keyData.raw.isEmpty)
    }
}
