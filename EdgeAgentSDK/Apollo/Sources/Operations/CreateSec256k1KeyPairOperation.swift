import ApolloLibrary
import Core
import Domain
import Foundation

struct CreateSec256k1KeyPairOperation {
    let logger: SDKLogger

    init(logger: SDKLogger = SDKLogger(category: .apollo)) {
        self.logger = logger
    }

    func compute(seed: Seed, keyPath: Domain.DerivationPath) throws -> PrivateKey {
        let derivedHdKey = ApolloLibrary.HDKey(
            seed: seed.value.toKotlinByteArray(),
            depth: 0,
            childIndex: 0
        ).derive(path: keyPath.keyPathString())
        return Secp256k1PrivateKey(internalKey: derivedHdKey.getKMMSecp256k1PrivateKey(), derivationPath: keyPath)

    }
}
