import ApolloLibrary
import CryptoKit
import Domain
import Foundation

struct Ed25519PrivateKey: PrivateKey {
    private let internalKey: ApolloLibrary.KMMEdPrivateKey
    let keyType: String = "EC"
    let keySpecifications: [String : String] = [
        "curve" : "Ed25519"
    ]
    var size: Int { raw.count }
    var raw: Data { internalKey.raw.toData() }

    init(internalKey: ApolloLibrary.KMMEdPrivateKey) {
        self.internalKey = internalKey
    }

    func publicKey() -> PublicKey {
        guard let publicKey = try? internalKey.publicKey() else {
            // TODO: This should never happen, but now we need to confirm if the Apollo domain needs to handle throwing or the library needs to remove it
            fatalError("This should never happen. PrivateKeys should always build a public")
        }
        return Ed25519PublicKey(internalKey: publicKey)
    }
}

extension Ed25519PrivateKey: SignableKey {
    var algorithm: String { "EDDSA" }

    func sign(data: Data) throws -> Signature {
        Signature(
            algorithm: "EdDSA",
            signatureSpecifications: ["algorithm" : algorithm],
            raw: try internalKey.sign(message: data.toKotlinByteArray()).toData()
        )
    }
}

extension Ed25519PrivateKey: KeychainStorableKey {
    var restorationIdentifier: String { "ed25519+priv" }
    var storableData: Data { raw }
    var index: Int? { nil }
    var type: Domain.KeychainStorableKeyProperties.KeyAlgorithm { .rawKey }
    var keyClass: Domain.KeychainStorableKeyProperties.KeyType { .privateKey }
    var accessiblity: Domain.KeychainStorableKeyProperties.Accessability? { .firstUnlock(deviceOnly: true) }
    var synchronizable: Bool { false }
}

struct Ed25519PublicKey: PublicKey {
    private let internalKey: ApolloLibrary.KMMEdPublicKey
    let keyType: String = "EC"
    let keySpecifications: [String : String] = [
        "curve" : "Ed25519"
    ]
    var size: Int { raw.count }
    var raw: Data { internalKey.raw.toData() }

    init(internalKey: ApolloLibrary.KMMEdPublicKey) {
        self.internalKey = internalKey
    }

    init(raw: Data) {
        self.init(internalKey: .init(raw: raw.toKotlinByteArray()))
    }

    func verify(data: Data, signature: Data) throws -> Bool {
        try internalKey.verify(message: data.toKotlinByteArray(), sig: signature.toKotlinByteArray())
    }
}

extension Ed25519PublicKey: KeychainStorableKey {
    var restorationIdentifier: String { "ed25519+pub" }
    var storableData: Data { raw }
    var index: Int? { nil }
    var type: Domain.KeychainStorableKeyProperties.KeyAlgorithm { .rawKey }
    var keyClass: Domain.KeychainStorableKeyProperties.KeyType { .publicKey }
    var accessiblity: Domain.KeychainStorableKeyProperties.Accessability? { .firstUnlock(deviceOnly: true) }
    var synchronizable: Bool { false }
}

