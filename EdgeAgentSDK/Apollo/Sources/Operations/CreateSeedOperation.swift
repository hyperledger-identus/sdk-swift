import ApolloLibrary
import Core
import Domain
import Foundation

struct CreateSeedOperation {
    let logger: SDKLogger
    let words: [String]
    let passphrase: String

    init(
        logger: SDKLogger = .init(category: LogComponent.apollo),
        words: [String],
        passphrase: String = ""
    ) throws {
        self.logger = logger
        self.words = words
        self.passphrase = passphrase
        guard ApolloLibrary.Mnemonic.companion.isValidMnemonicCode(code: words) else {
            logger.error(
                message: "Invalid mnemonic word",
                metadata: words
                    .enumerated()
                    .map {
                        .publicMetadata(key: "word\($0)", value: $1)
                    }
            )
            throw ApolloError.invalidMnemonicWord(invalidWords: Array(words))
        }
    }

    func compute() throws -> Seed {
        Seed(
            value: try ApolloLibrary
                .Mnemonic
                .companion
                .createSeed(mnemonics: words, passphrase: passphrase).toData()
        )
    }
}
