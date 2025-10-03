import Core
import Foundation

/// A Verifiable Presentation container aligned with the W3C VC Data Model
///
/// `VerifiablePresentation` models the core structure of a W3C Verifiable Presentation
/// (VP). It is designed to interoperate across VCDM 1.0, 1.1, and 2.0 by supporting
/// JSON‑LD `@context` and `type` as one‑or‑many values and by letting you choose the
/// representation of embedded credentials via the `Credential` generic.
///
/// - Generics:
///   - `Credential`: The type used for the `verifiableCredential` field. Use a single
///     credential model (e.g., `DefaultVerifiableCredential`) or wrap it in
///     `OneOrMany<...>` to support multiple credentials in one presentation.
///
/// - Notable behavior:
///   - `@context` and `type` are modeled as `OneOrMany<String>` to match ecosystem usage.
///   - The `verifiableCredential` field can be either a single credential or a collection,
///     depending on the chosen `Credential` generic (e.g., `OneOrMany<DefaultVerifiableCredential>`).
///   - Unknown fields are preserved for round‑tripping through the underlying raw storage.
///
/// - Conforms to:
///   - `RawCodable`, `Codable`
///
/// - See also:
///   - W3C Verifiable Credentials Data Model 1.0 (2019): https://www.w3.org/TR/2019/REC-vc-data-model-20191119/
///   - W3C Verifiable Credentials Data Model 1.1: https://www.w3.org/TR/vc-data-model-1.1/
///   - W3C Verifiable Credentials Data Model 2.0: https://www.w3.org/TR/vc-data-model-2.0/
///   - `VerifiableCredential`, `DefaultVerifiableCredential`, `OneOrMany`, `RawCodable`, `Codable`
public struct VerifiablePresentation<Credential: RawCodable>: RawCodable {

    public enum CodingKeys: String, CodingKey {
        case context = "@context"
        case type
        case verifiableCredential
    }
    
    /// The JSON-LD `@context` values for the presentation (one-or-many).
    public let context: OneOrMany<String>
    /// The presentation type(s). Typically includes "VerifiablePresentation".
    public let type: OneOrMany<String>
    /// The embedded credential(s). Choose `Credential` as a single VC type or wrap in
    /// `OneOrMany<...>` to support multiple credentials.
    public let verifiableCredential: Credential
    public let raw: AnyCodable?

    /// Creates a new Verifiable Presentation value.
    ///
    /// - Parameters:
    ///   - context: The JSON-LD `@context` values for the presentation (one-or-many).
    ///   - type: The presentation type(s), typically including "VerifiablePresentation".
    ///   - verifiableCredential: The embedded credential(s). Supply either a single VC
    ///     type or `OneOrMany<...>` to support multiple credentials.
    public init(
        context: OneOrMany<String>,
        type: OneOrMany<String>,
        verifiableCredential: Credential,
        raw: AnyCodable? = nil
    ) {
        self.context = context
        self.type = type
        self.verifiableCredential = verifiableCredential
        self.raw = raw
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.context = try container.decode(OneOrMany<String>.self, forKey: .context)
        self.type = try container.decode(OneOrMany<String>.self, forKey: .type)
        self.verifiableCredential = try container.decode(Credential.self, forKey: .verifiableCredential)
        self.raw = try AnyCodable(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        guard let raw else {
            var container = encoder.container(keyedBy: VerifiablePresentation<Credential>.CodingKeys.self)
            try container.encode(self.context, forKey: .context)
            try container.encode(self.type, forKey: .type)
            try container.encode(self.verifiableCredential, forKey: .verifiableCredential)
            return
        }
        try raw.encode(to: encoder)
    }
}
