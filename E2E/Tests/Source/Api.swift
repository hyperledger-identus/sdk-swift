import Foundation
import TestFramework

class Api {
    static func get(from url: URL) async throws -> [String : Any] {
        let session = URLSession.shared
        let (data, _) = try await session.data(from: url)
        let response = try (JSONSerialization.jsonObject(with: data, options: []) as? [String: Any])!
        return response
    }
    
    static func get(from url: URL) async throws -> String {
        let session = URLSession.shared
        let (data, _) = try await session.data(from: url)
        let response = String(bytes: data, encoding: String.Encoding.utf8)!
        return response
    }
}

class ApiError {
    final class failure: BaseError {
        init(message: String, file: StaticString = #file, line: UInt = #line) {
            super.init(message: message, error: "Failure using API", file: file, line: line)
        }
    }
}
