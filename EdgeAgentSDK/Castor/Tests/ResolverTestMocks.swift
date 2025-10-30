import Foundation
import Domain
@testable import Castor

// Simple error for forcing failures in mocks
enum MockError: Error { case forced }

// MARK: - Downloader Mock
final class DownloaderMock: Downloader {
    private(set) var requests: [String] = []
    var result: Result<Data, Error>

    init(result: Result<Data, Error>) {
        self.result = result
    }

    func downloadFromEndpoint(urlOrDID: String) async throws -> Data {
        requests.append(urlOrDID)
        return try result.get()
    }
}

// MARK: - URL Builder Mock
final class DIDDocumentUrlBuilderMock: DIDDocumentUrlBuilder {
    private(set) var dids: [DID] = []
    var endpoint: String
    var error: Error?

    init(endpoint: String = "https://example.com/did.json", error: Error? = nil) {
        self.endpoint = endpoint
        self.error = error
    }

    func didDocumentEndpoint(did: DID) throws -> String {
        dids.append(did)
        if let error { throw error }
        return endpoint
    }
}

// MARK: - Serializer Mock
final class DIDDocumentSerializerMock: DIDDocumentSerializer {
    private(set) var datas: [Data] = []
    var result: Result<DIDDocument, Error>

    init(result: Result<DIDDocument, Error>) {
        self.result = result
    }

    func serialize(data: Data) throws -> DIDDocument {
        datas.append(data)
        return try result.get()
    }
}

// MARK: - Generic DID Resolver Mock
final class DIDResolverMock: DIDResolverDomain {
    var method: DIDMethod = "prism"
    private(set) var calls: [DID] = []
    var result: Result<DIDDocument, Error>

    init(result: Result<DIDDocument, Error>) {
        self.result = result
    }

    func resolve(did: DID) async throws -> DIDDocument {
        calls.append(did)
        return try result.get()
    }
}
