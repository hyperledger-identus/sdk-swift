import Core
import Domain
import Foundation

/// A minimal descriptor for an enveloped Verifiable Presentation entry
///
/// `EnvelopedVerfiablePresentation` represents a compact, JSON‑LD object used when
/// embedding or referencing a Verifiable Credential within a Verifiable Presentation
/// (VP). In JWT‑based flows, this is commonly used to reference a VC by a data URI
/// (e.g., `data:application/vc+jwt,<jwt>`), while still providing JSON‑LD context
/// and type information.
///
/// This structure is intended to interoperate across VCDM 1.0, 1.1, and 2.0. The
/// defaults reflect modern usage (VCDM 2.0 contexts and types), but callers may
/// override them as needed for compatibility.
///
/// - Conforms to:
///   - `RawCodable`, `Codable`
///
/// - See also:
///   - W3C Verifiable Credentials Data Model 1.0 (2019): https://www.w3.org/TR/2019/REC-vc-data-model-20191119/
///   - W3C Verifiable Credentials Data Model 1.1: https://www.w3.org/TR/vc-data-model-1.1/
///   - W3C Verifiable Credentials Data Model 2.0: https://www.w3.org/TR/vc-data-model-2.0/
///   - `VerifiablePresentation`, `DefaultVerifiableCredential`, `JWTCredential`, `OneOrMany`
public struct EnvelopedVerfiablePresentation: RawCodable {
    enum CodingKeys: String, CodingKey {
        case context = "@context"
        case type
        case id
    }

    /// The JSON‑LD `@context` values for the enveloped presentation entry (one‑or‑many).
    public let context: OneOrMany<String>

    /// Identifier for the embedded credential reference.
    ///
    /// In JWT flows, this is typically a data URI like `data:application/vc+jwt,<jwt>`.
    public let id: String

    /// The type(s) for the enveloped entry. Defaults to "EnvelopedVerifiablePresentation".
    public let type: OneOrMany<String>
    public let raw: AnyCodable?

    /// Creates an enveloped presentation entry.
    ///
    /// - Parameters:
    ///   - context: The JSON‑LD `@context` values (defaults to VCDM 2.0 context).
    ///   - id: Identifier for the embedded credential reference (e.g., data URI for a VC‑JWT).
    ///   - type: The JSON‑LD type(s) for the entry (defaults to "EnvelopedVerifiablePresentation").
    public init(
        context: OneOrMany<String> = .one("https://www.w3.org/ns/credentials/v2"),
        id: String,
        type: OneOrMany<String> = .one("EnvelopedVerifiablePresentation"),
        raw: AnyCodable? = nil
    ) {
        self.context = context
        self.id = id
        self.type = type
        self.raw = raw
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.context = try container.decodeIfPresent(OneOrMany<String>.self, forKey: .context) ?? .many([])
        self.id = try container.decode(String.self, forKey: .id)
        self.type = try container.decodeIfPresent(OneOrMany<String>.self, forKey: .type) ?? .many([])
        self.raw = try AnyCodable(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        guard let raw else {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(context, forKey: .context)
            try container.encode(id, forKey: .id)
            try container.encode(type, forKey: .type)
            return
        }

        try raw.encode(to: encoder)
    }
}

/// A JOSE (JWT) envelope for a Verifiable Presentation (VP-JWT)
///
/// `JWTEnvelopedVerifiablePresentation` models the registered JWT claims commonly
/// used when transporting a Verifiable Presentation inside a JWT (VP‑JWT). The
/// VP itself is provided via the generic `vp` payload, enabling you to embed your
/// preferred presentation structure.
///
/// This type interoperates with VCDM 1.0, 1.1, and 2.0 and typical JOSE/JWT
/// ecosystems. It normalizes audience (`aud`) to an array during decoding to
/// accommodate both string and array encodings.
///
/// - Generics:
///   - `VerifiablePresentation`: The payload type for the `vp` claim. For example,
///     use `VerifiablePresentation<EnvelopedVerfiablePresentation>` for a minimal
///     VP structure that references a VC‑JWT by data URI.
///
/// - Conforms to:
///   - `RawCodable`
///
/// - See also:
///   - W3C Verifiable Credentials Data Model 1.0 (2019): https://www.w3.org/TR/2019/REC-vc-data-model-20191119/
///   - W3C Verifiable Credentials Data Model 1.1: https://www.w3.org/TR/vc-data-model-1.1/
///   - W3C Verifiable Credentials Data Model 2.0: https://www.w3.org/TR/vc-data-model-2.0/
///   - JSON Web Token (JWT): https://www.rfc-editor.org/rfc/rfc7519
///   - JSON Web Signature (JWS): https://www.rfc-editor.org/rfc/rfc7515
///   - `VerifiablePresentation`, `EnvelopedVerfiablePresentation`, `JWTCredential`
public struct JWTEnvelopedVerifiablePresentation<VerifiablePresentation: Codable>: RawCodable {
    /// Issuer of the VP‑JWT (typically a DID URI).
    public let iss: String?
    /// Subject of the VP‑JWT (optional; may be omitted depending on flow).
    public let sub: String?
    /// Not‑before time indicating when the VP‑JWT becomes valid.
    public let nbf: Date?
    /// Expiration time for the VP‑JWT.
    public let exp: Date?
    /// Issued‑at time for the VP‑JWT.
    public let iat: Date?
    /// Unique identifier for the VP‑JWT.
    public let jti: String?
    /// Audience for the VP‑JWT. Decoding accepts either a single string or an array and normalizes to an array.
    public let aud: [String]?
    /// Challenge/nonce used to bind the VP to a specific request (anti‑replay).
    public let nonce: String?
    /// The embedded Verifiable Presentation payload carried in this VP‑JWT.
    public let vp: VerifiablePresentation
    public var raw: AnyCodable?

    init(
        iss: String? = nil,
        sub: String? = nil,
        nbf: Date? = nil,
        exp: Date? = nil,
        iat: Date? = nil,
        jti: String? = nil,
        aud: [String]? = nil,
        nonce: String? = nil,
        vp: VerifiablePresentation,
        raw: AnyCodable? = nil
    ) {
        self.iss = iss
        self.sub = sub
        self.nbf = nbf
        self.exp = exp
        self.iat = iat
        self.jti = jti
        self.aud = aud
        self.nonce = nonce
        self.vp = vp
        self.raw = raw
    }

    enum CodingKeys: CodingKey {
        case iss
        case sub
        case nbf
        case exp
        case iat
        case jti
        case aud
        case nonce
        case vp
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        iss = try container.decodeIfPresent(String.self, forKey: .iss)
        sub = try container.decodeIfPresent(String.self, forKey: .sub)
        nbf = try container.decodeIfPresent(Date.self, forKey: .nbf)
        exp = try container.decodeIfPresent(Date.self, forKey: .exp)
        iat = try container.decodeIfPresent(Date.self, forKey: .iat)
        jti = try container.decodeIfPresent(String.self, forKey: .jti)
        nonce = try container.decodeIfPresent(String.self, forKey: .nonce)
        if let aud = try? container.decodeIfPresent([String].self, forKey: .aud) {
            self.aud = aud
        } else if let aud = try? container.decodeIfPresent(String.self, forKey: .aud) {
            self.aud = [aud]
        } else {
            aud = nil
        }

        if let vp = try container.decodeIfPresent(VerifiablePresentation.self, forKey: .vp) {
            self.vp = vp
        } else {
            self.vp = try VerifiablePresentation(from: decoder)
        }
        raw = try AnyCodable(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        guard let raw else {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(self.iss, forKey: .iss)
            try container.encodeIfPresent(self.sub, forKey: .sub)
            try container.encodeIfPresent(self.nbf, forKey: .nbf)
            try container.encodeIfPresent(self.exp, forKey: .exp)
            try container.encodeIfPresent(self.iat, forKey: .iat)
            try container.encodeIfPresent(self.jti, forKey: .jti)
            try container.encodeIfPresent(self.aud, forKey: .aud)
            try container.encodeIfPresent(self.nonce, forKey: .nonce)
            try container.encode(self.vp, forKey: .vp)
            return
        }
        try raw.encode(to: encoder)
    }
}
