import Domain
import Foundation

public extension EndpointShortFormPrismDIDRemoteResolver {
    static func githubResolver() -> Self {
        .init(
            urlBuilder: GitHubResolverURLBuilder(),
            downloader: DownloadDataWithResolver(),
            serializer: GitHubResolverDIDDocumentSerializer()
        )
    }
}

public struct GitHubResolverURLBuilder: DIDDocumentUrlBuilder {
    let baseURL = "https://raw.githubusercontent.com/FabioPinheiro/prism-vdr/refs/heads/main/mainnet/diddoc/"

    public func didDocumentEndpoint(did: DID) throws -> String {
        return baseURL.appending(did.string)
    }
}

public struct GitHubResolverDIDDocumentSerializer: DIDDocumentSerializer {
    let coder: JSONDecoder

    init(coder: JSONDecoder = .normalized) {
        self.coder = coder
    }

    public func serialize(data: Data) throws -> DIDDocument {
        return try coder.decode(DIDDocument.self, from: data)
    }
}

fileprivate struct DownloadDataWithResolver: Downloader {

    func downloadFromEndpoint(urlOrDID: String) async throws -> Data {
        let url: URL

        if let validUrl = URL(string: urlOrDID.replacingOccurrences(of: "host.docker.internal", with: "localhost")) {
            url = validUrl
        } else {
            throw CommonError.invalidURLError(url: urlOrDID)
        }

        let (data, urlResponse) = try await URLSession.shared.data(from: url)

        guard
            let code = (urlResponse as? HTTPURLResponse)?.statusCode,
            200...299 ~= code
        else {
            throw CommonError.httpError(
                code: (urlResponse as? HTTPURLResponse)?.statusCode ?? 500,
                message: String(data: data, encoding: .utf8) ?? ""
            )
        }

        return data
    }
}
