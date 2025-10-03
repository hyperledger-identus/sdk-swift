import Core
import Foundation

/// The `AttachmentData` protocol represents a generic attachment for a DIDComm `Message`. Any type that conforms to `AttachmentData` can be used as an attachment.
public protocol AttachmentData: Codable {}

/// The `AttachmentHeader` struct represents the header for a DIDComm attachment.
public struct AttachmentHeader: AttachmentData {
    /// The `children` value associated with the attachment.
    public let children: String

    /// Initializes a new `AttachmentHeader` object with the specified properties.
    /// - Parameter children: The `children` value associated with the attachment.
    public init(children: String) {
        self.children = children
    }
}

/// The `AttachmentJws` struct represents a DIDComm attachment containing a JWS (JSON Web Signature).
public struct AttachmentJws: AttachmentData {
    /// The header for the JWS attachment.
    public let header: AttachmentHeader

    /// The `protected` value associated with the JWS.
    public let protected: String

    /// The signature for the JWS.
    public let signature: String

    /// Initializes a new `AttachmentJws` object with the specified properties.
    /// - Parameters:
    ///   - header: The header for the JWS attachment.
    ///   - protected: The `protected` value associated with the JWS.
    ///   - signature: The signature for the JWS.
    public init(header: AttachmentHeader, protected: String, signature: String) {
        self.header = header
        self.protected = protected
        self.signature = signature
    }
}

/// The `AttachmentJwsData` struct represents a DIDComm attachment containing JWS data.
public struct AttachmentJwsData: AttachmentData {
    /// The base64-encoded data for the JWS.
    public let base64: String

    /// The `AttachmentJws` object containing the JWS data.
    public let jws: AttachmentJws

    /// Initializes a new `AttachmentJwsData` object with the specified properties.
    /// - Parameters:
    ///   - base64: The base64-encoded data for the JWS.
    ///   - jws: The `AttachmentJws` object containing the JWS data.
    public init(base64: String, jws: AttachmentJws) {
        self.base64 = base64
        self.jws = jws
    }
}

/// The `AttachmentBase64` struct represents a DIDComm attachment containing base64-encoded data.
public struct AttachmentBase64: AttachmentData {
    /// The base64-encoded data.
    public let base64: String

    /// Initializes a new `AttachmentBase64` object with the specified properties.
    /// - Parameter base64: The base64-encoded data.
    public init(base64: String) {
        self.base64 = base64
    }
    
    public func decoded() throws -> Data {
        guard let decode = Data(base64Encoded: base64) else {
            throw CommonError.invalidCoding(message: "Could not decode base64 message attchment")
        }
        return decode
    }
}

/// The `AttachmentLinkData` struct represents a DIDComm attachment containing a link to external data.
public struct AttachmentLinkData: AttachmentData {
    /// The links associated with the attachment.
    public let links: [String]

    /// The hash associated with the attachment.
    public let hash: String

    /// Initializes a new `AttachmentLinkData` object with the specified properties.
    /// - Parameters:
    ///   - links: The links associated with the attachment.
    ///   - hash: The hash associated with the attachment.
    public init(links: [String], hash: String) {
        self.links = links
        self.hash = hash
    }
}

/// The `AttachmentJsonData` struct represents a DIDComm attachment containing JSON data.
public struct AttachmentJsonData: AttachmentData {
    /// The JSON data associated with the attachment.
    public let json: AnyCodable

    /// Initializes a new `AttachmentJsonData` object with the specified properties.
    /// - Parameter data: The JSON data associated with the attachment.
    public init(json: AnyCodable) {
        self.json = json
    }
}

/// The `AttachmentDescriptor` struct represents metadata for a DIDComm attachment.
public struct AttachmentDescriptor {
    /// The ID associated with the attachment.
    public let id: String

    /// The media type associated with the attachment.
    public let mediaType: String?

    /// The data associated with the attachment.
    public let data: AttachmentData

    /// The filename associated with the attachment.
    public let filename: [String]?

    /// The format associated with the attachment.
    public let format: String?

    /// The last modification time associated with the attachment.
    public let lastmodTime: Date?

    /// The byte count associated with the attachment.
    public let byteCount: Int?

    /// The description associated with the attachment.
    public let description: String?

    /// Initializes a new `AttachmentDescriptor` object with the specified properties.
    /// - Parameters:
    ///   - id: The ID associated with the attachment.
    ///   - mediaType: The media type associated with the attachment.
    ///   - data: The data associated with the attachment.
    ///   - filename: The filename associated with the attachment.
    ///   - format: The format associated with the attachment.
    ///   - lastmodTime: The last modification time associated with the attachment.
    ///   - byteCount: The byte count associated with the attachment.
    ///   - description: The description associated with the attachment.
    public init(
        id: String = UUID().uuidString,
        mediaType: String? = nil,
        data: AttachmentData,
        filename: [String]? = nil,
        format: String? = nil,
        lastmodTime: Date? = nil,
        byteCount: Int? = nil,
        description: String? = nil
    ) {
        self.id = id
        self.mediaType = mediaType
        self.data = data
        self.filename = filename
        self.format = format
        self.lastmodTime = lastmodTime
        self.byteCount = byteCount
        self.description = description
    }
}

extension AttachmentDescriptor: Codable {
    
    enum CodingKeys: String, CodingKey {
        case id
        case mediaType
        case data
        case filename
        case format
        case lastmodTime
        case byteCount
        case description
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(mediaType, forKey: .mediaType)
        try container.encode(data, forKey: .data)
        try container.encodeIfPresent(filename, forKey: .filename)
        try container.encodeIfPresent(format, forKey: .format)
        try container.encodeIfPresent(lastmodTime, forKey: .lastmodTime)
        try container.encodeIfPresent(byteCount, forKey: .byteCount)
        try container.encodeIfPresent(description, forKey: .description)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let mediaType = try? container.decodeIfPresent(String.self, forKey: .mediaType)
        let filename = try? container.decodeIfPresent([String].self, forKey: .filename)
        let format = try? container.decodeIfPresent(String.self, forKey: .format)
        let lastmodTime = try? container.decodeIfPresent(Date.self, forKey: .lastmodTime)
        let byteCount = try? container.decodeIfPresent(Int.self, forKey: .byteCount)
        let description = try? container.decodeIfPresent(String.self, forKey: .description)
        let data: AttachmentData?
        if let attchData = try? container.decode(AttachmentBase64.self, forKey: .data) {
            data = attchData
        } else if let attchData = try? container.decode(AttachmentJws.self, forKey: .data) {
            data = attchData
        } else if let attchData = try? container.decode(AttachmentHeader.self, forKey: .data) {
            data = attchData
        } else if let attchData = try? container.decode(AttachmentJwsData.self, forKey: .data) {
            data = attchData
        } else if let attchData = try? container.decode(AttachmentJsonData.self, forKey: .data) {
            data = attchData
        } else if let attchData = try? container.decode(AttachmentLinkData.self, forKey: .data) {
            data = attchData
        } else { data = nil }
        
        guard let data else { throw CommonError.invalidCoding(
            message: """
Could not parse AttachmentData to any of the following: AttachmentBase64, AttachmentJws, AttachmentHeader, AttachmentJwsData, AttachmentJsonData, AttachmentLinkData
"""
        )}

        self.init(
            id: id,
            mediaType: mediaType,
            data: data,
            filename: filename,
            format: format,
            lastmodTime: lastmodTime,
            byteCount: byteCount,
            description: description
        )
    }
}
