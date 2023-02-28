import Core
import Domain
import Foundation

public struct CastorImpl {
    let apollo: Apollo
    let resolvers: [DIDResolverDomain]
    let logger: PrismLogger

    public init(apollo: Apollo, resolvers: [DIDResolverDomain] = []) {
        self.logger = PrismLogger(category: .castor)
        self.apollo = apollo
        self.resolvers = resolvers + [
            LongFormPrismDIDResolver(apollo: apollo, logger: logger),
            PeerDIDResolver()
        ]
    }

    func verifySignature(document: DIDDocument, signature: String, challenge: String) -> Bool {
        return false
    }
}
