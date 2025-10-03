import Core
import Foundation

/// A generic sum type for fields that can be either a DID/URI string or an expanded object
///
/// This type models the dual representation used in the W3C Verifiable Credentials
/// and Verifiable Presentations data model. Certain properties in VC/VP may be
/// represented as a string identifier (typically a DID or URI) or as a fully
/// expanded object with an `id` field. Examples include:
/// - VC: `issuer` can be a string (DID/URI) or an object with `id`
/// - VP: `holder` can be a string (DID/URI) or an object with `id`
///
/// `IssuerDefaultObject` captures this duality in a single, type-safe enum so that
/// code consuming VC/VP data can work uniformly with either representation.
///
/// - Generic Parameter:
///   - IssuerObject: The concrete type of the expanded object. It must conform to
///     both `Identifiable` and `RawCodable`. When `IssuerObject.ID == String`, a
///     convenience `id` property is available (via an extension) to retrieve the
///     identifier regardless of whether the enum holds a string DID/URI or an object.
///
/// - Cases:
///   - `id(_:)`: Holds the string identifier (typically a DID or URI).
///   - `object(_:)`: Holds the fully materialized `IssuerObject` (whose `id` is
///     expected to be the DID/URI string when `IssuerObject.ID == String`).
///
/// - Codable Behavior:
///   - Decoding: Uses a single value container. It first attempts to decode a
///     `String` (interpreted as the DID/URI). If that fails, it decodes
///     `IssuerObject` and stores it as `.object(IssuerObject)`.
///   - Encoding: Uses a single value container. If the enum is `.id`, it encodes
///     the `String` directly; if `.object`, it encodes the full `IssuerObject`.
///
/// - Usage:
///   ```swift
///   // Example expanded subject that can appear in a VP's `holder` or a VC's `issuer`.
///   struct DIDSubject: Identifiable, RawCodable {
///       let id: String  // DID or URI
///       let name: String?
///   }
///
///   struct VerifiablePresentation: RawCodable {
///       // The holder may be a DID/URI string or an expanded object with `id`.
///       let holder: IssuerDefaultObject<DIDSubject>
///   }
///
///   // Access the DID/URI regardless of representation when ID == String:
///   let holderDID = vp.holder.id
///   ```
///
/// - Conforms to:
///   - `Codable`
///
/// - See also:
///   - W3C Verifiable Credentials Data Model: https://www.w3.org/TR/vc-data-model/
///   - W3C Verifiable Presentations (within VC Data Model): https://www.w3.org/TR/vc-data-model/#presentations
///   - `Identifiable`, `RawCodable`, `Codable`
public enum IssuerDefaultObject<IssuerObject: Identifiable & RawCodable> {
    case id(String)
    case object(IssuerObject)
}

/// Convenience for VC/VP-style identifiers: returns the DID/URI whether this value
/// holds a raw string or an expanded object whose `id` is that string.
extension IssuerDefaultObject where IssuerObject.ID == String {
    public var id: String {
        switch self {
        case .id(let s): return s
        case .object(let o): return o.id
        }
    }
}

/// Decodes from either a DID/URI string or an expanded object (with `id`), and
/// encodes back as the same single-value representation.
extension IssuerDefaultObject: Codable {
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let s = try? c.decode(String.self) {
            self = .id(s)
        } else {
            self = .object(try c.decode(IssuerObject.self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .id(let s): try c.encode(s)
        case .object(let o): try c.encode(o)
        }
    }
}

