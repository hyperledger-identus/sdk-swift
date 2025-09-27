import Domain
import Foundation

public struct DownloadDataWithResolver: Downloader {
    let castor: Castor
    
    init(castor: Castor) {
        self.castor = castor
    }
    
    public func downloadFromEndpoint(urlOrDID: String) async throws -> Data {
        let url: URL

        if let did = try? castor.parseDID(str: urlOrDID) {
            let document = try await castor.resolveDID(did: did)
            guard 
                let urlStr = document.services.first?.serviceEndpoint.array.first?.uri,
                let validUrl = URL(string: urlStr)
            else {
                throw CommonError.invalidURLError(url: "Could not find any URL on DID")
            }
            url = validUrl
        } else if let validUrl = URL(string: urlOrDID.replacingOccurrences(of: "host.docker.internal", with: "localhost")) {
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
