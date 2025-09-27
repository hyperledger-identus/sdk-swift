import Foundation

/// Represents a DIDUrl with "did", "path", "parameters", "fragment"
/// As specified in [w3 standards](`https://www.w3.org/TR/did-core/#dfn-did-urls`)
public struct DIDUrl: Hashable, Equatable, Codable {
    /// The associated Decentralized Identifier (DID).
    public let did: DID

    /// The path component of the DIDUrl.
    /// An array of string fragments representing the path segments.
    public let path: [String]

    /// The parameters component of the DIDUrl.
    /// A dictionary mapping parameter keys to their associated values.
    public let parameters: [String: String]

    /// The fragment component of the DIDUrl.
    /// An optional string representing the fragment.
    public let fragment: String?

    /// Initializes a new `DIDUrl` with the given components.
    /// - Parameters:
    ///   - did: The associated Decentralized Identifier (DID).
    ///   - path: An array of string fragments representing the path segments.
    ///   - parameters: A dictionary mapping parameter keys to their associated values.
    ///   - fragment: An optional string representing the fragment.
    public init(
        did: DID,
        path: [String] = [],
        parameters: [String: String] = [:],
        fragment: String? = nil
    ) {
        self.did = did
        self.path = path
        self.parameters = parameters
        self.fragment = fragment
    }

    public init(string: String) throws {
        let regexPattern = #"^did:([^:/?#]+):([^?#]*)(?:\?([^#]*))?(?:#(.*))?$"#
        let regex = try? NSRegularExpression(pattern: regexPattern)
        guard let match = regex?.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)) else {
            throw CastorError.invalidDIDString(string)
        }

        // Extract DID Method
        guard let methodRange = Range(match.range(at: 1), in: string) else {
            throw CastorError.invalidDIDString(string)
        }
        let method = String(string[methodRange])

        // Extract methodId and path from the second capturing group
        guard let fullMethodIdRange = Range(match.range(at: 2), in: string) else {
            throw CastorError.invalidDIDString(string)
        }
        let fullMethodIdComponents = string[fullMethodIdRange].split(separator: "/", maxSplits: 1)
        let methodId = String(fullMethodIdComponents[0])
        let path = fullMethodIdComponents.count > 1 ? "/" + String(fullMethodIdComponents[1]) : nil

        // Construct the DID instance
        did = DID(schema: "did", method: method, methodId: methodId)

        // Extract Queries
        if let queriesRange = Range(match.range(at: 3), in: string) {
            let queryString = String(string[queriesRange])
            let queryPairs = queryString.split(separator: "&").map { $0.split(separator: "=") }
            var queries: [String: String] = [:]
            for pair in queryPairs {
                if pair.count == 2 {
                    queries[String(pair[0])] = String(pair[1])
                }
            }
            self.parameters = queries
        } else {
            self.parameters = [:]
        }

        self.path = path?.components(separatedBy: "/").filter { !$0.isEmpty } ?? []

        // Extract Fragment
        if let fragmentRange = Range(match.range(at: 4), in: string) {
            self.fragment = String(string[fragmentRange])
        } else {
            self.fragment = nil
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        try self.init(string: string)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(string)
    }

    /// A string representation of this `DIDUrl`.
    public var string: String {
        did.string + pathString + queryString + fragmentString
    }

    /// A string representation of the path component of this `DIDUrl`.
    private var pathString: String {
        path.isEmpty ? "" : "/" + path.joined(separator: "/")
    }

    /// A string representation of the parameters component of this `DIDUrl`.
    private var queryString: String {
        parameters.isEmpty ? "" : "?" + parameters.map { $0.key + "=" + $0.value }.joined(separator: "&")
    }

    /// A string representation of the fragment component of this `DIDUrl`.
    private var fragmentString: String {
        fragment.map { "#" + $0 } ?? ""
    }
}
