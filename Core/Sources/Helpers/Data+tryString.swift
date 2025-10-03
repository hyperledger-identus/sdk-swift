import Foundation

public struct InvalidCoding: Error {
    let localizedDescription: String

    public init(message: String) {
        self.localizedDescription = message
    }
}

public extension Data {
    func toString(using: String.Encoding = .utf8) throws -> String {
        guard let str = String(data: self, encoding: using) else {
            throw InvalidCoding(message: "Could not get String from Data value")
        }
        return str
    }
}
