import Core
import Domain
import Foundation

public struct CastorImpl {
    let apollo: Apollo
    let resolvers: [DIDResolverDomain]
    let logger: SDKLogger

    public init(apollo: Apollo, resolvers: [DIDResolverDomain] = []) {
        self.logger = SDKLogger(category: LogComponent.castor)
        self.apollo = apollo
        self.resolvers = resolvers + [
            CompactPrismDIDResolver(
                longFormResolver: LongFormPrismDIDResolver(apollo: apollo, logger: logger),
                shortFormResolver: EndpointShortFormPrismDIDRemoteResolver.githubResolver()
            ),
            PeerDIDResolver()
        ]
    }

    func verifySignature(document: DIDDocument, signature: String, challenge: String) -> Bool {
        return false
    }
}
