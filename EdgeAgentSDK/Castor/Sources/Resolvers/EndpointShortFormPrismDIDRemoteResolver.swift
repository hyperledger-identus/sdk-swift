import Domain
import Foundation

public protocol DIDDocumentUrlBuilder {
    func didDocumentEndpoint(did: DID) throws -> String
}

public protocol DIDDocumentSerializer {
    func serialize(data: Data) throws -> DIDDocument
}

public struct EndpointShortFormPrismDIDRemoteResolver: DIDResolverDomain {
    public let method = "prism"
    let urlBuilder: DIDDocumentUrlBuilder
    let downloader: Downloader
    let serializer: DIDDocumentSerializer

    init(urlBuilder: DIDDocumentUrlBuilder, downloader: Downloader, serializer: DIDDocumentSerializer) {
        self.urlBuilder = urlBuilder
        self.downloader = downloader
        self.serializer = serializer
    }

    public func resolve(did: DID) async throws -> DIDDocument {
        let did = try did.removingPrismLongForm()
        let data = try await downloader.downloadFromEndpoint(urlOrDID: urlBuilder.didDocumentEndpoint(did: did))
        return try serializer.serialize(data: data)
    }
}

private extension DID {
    func removingPrismLongForm() throws -> DID {
        let separated = string
            .split(separator: ":")
        let shortForm = separated.prefix(3).joined(separator: ":")
        return try DID(string: shortForm)
    }
}
