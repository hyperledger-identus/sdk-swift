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
