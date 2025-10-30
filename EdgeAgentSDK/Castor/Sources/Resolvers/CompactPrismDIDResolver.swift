import Domain

public struct CompactPrismDIDResolver: DIDResolverDomain {
    public let method = "prism"
    let longFormResolver: DIDResolverDomain
    let shortFormResolver: DIDResolverDomain

    init(longFormResolver: DIDResolverDomain, shortFormResolver: DIDResolverDomain) {
        self.longFormResolver = longFormResolver
        self.shortFormResolver = shortFormResolver
    }

    public func resolve(did: Domain.DID) async throws -> Domain.DIDDocument {
        do {
            return try await shortFormResolver.resolve(did: did)
        } catch {
            guard did.isLongFormDID() else { throw error }
            return try await longFormResolver.resolve(did: did)
        }
    }
}

private extension DID {
    func isLongFormDID() -> Bool {
        return string.split(separator: ":").count > 3
    }
}
