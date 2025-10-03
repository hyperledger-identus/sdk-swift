import Foundation

/**
 A struct representing a container for verifiable credential types.

 This struct is used to encode and decode verifiable credential types for use with JSON.

 The VerifiableCredentialTypeContainer struct contains properties for the ID and type of the verifiable credential.

 - Note: The VerifiableCredentialTypeContainer struct is used to encode and decode verifiable credential types for use with JSON.

 */
public struct VerifiableCredentialTypeContainer: Codable {

    // Enum to define the two coding keys for encoding and decoding
    enum CodingKeys: String, CodingKey {
        case id = "@id"
        case type = "@type"
    }

    // The ID of the verifiable credential type
    public let id: String

    // The type of the verifiable credential
    public let type: String

    /**
     Encodes the verifiable credential type container to the specified encoder.

     - Parameter encoder: The encoder to use for encoding.

     */
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.type, forKey: .type)
    }

    /**
     Initializes a new instance of the VerifiableCredentialTypeContainer struct from the specified decoder.

     - Parameter decoder: The decoder to use for decoding.

     */
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.type = try container.decode(String.self, forKey: .type)
    }
}
