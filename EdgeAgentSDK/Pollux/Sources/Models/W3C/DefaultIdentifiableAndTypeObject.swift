import Core
import Foundation

/// A lightweight, lossless container that exposes only an identifier and a type (or types),
/// while preserving the original, unmodeled payload for round‑tripping.
///
/// This type is useful when you:
/// - Need quick access to an object's identity and classification without fully modeling its schema.
/// - Want to decode unknown or evolving payloads and later re‑encode them exactly as they were received.
/// - Work with formats that may express a type as either a single string or an array of strings.
///
/// Key characteristics:
/// - Conforms to `Identifiable` via the `id` property.
/// - Conforms to `RawCodable`, capturing the full, original payload in `raw`.
/// - On decoding, extracts `id` and `type` and stores the entire payload in `raw`.
/// - On encoding, prefers emitting the original `raw` payload verbatim if available; otherwise encodes only `id` and `type`.
///
/// Example payloads:
/// - Single type:
///   { "id": "123", "type": "Book", "title": "Swift Patterns" }
/// - Multiple types:
///   { "id": "123", "type": ["Book", "Ebook"], "title": "Swift Patterns" }
///
/// Decoding example:
/// ```swift
/// let object = try JSONDecoder().decode(DefaultIdentifiableAndTypeObject.self, from: data)
/// print(object.id)              // "123"
/// print(object.type.values)     // ["Book"] or ["Book", "Ebook"]
/// print(object.raw != nil)      // true — original payload preserved
/// ```
///
/// Encoding behavior:
/// - If `raw` is non‑nil, encoding writes the original payload unchanged (lossless round‑trip).
/// - If `raw` is nil (e.g., you constructed the value by hand), only `id` and `type` are encoded.
///
/// Performance and safety notes:
/// - `DefaultIdentifiableAndTypeObject` is a value type; copying it also copies the `raw` payload,
///   which may be large depending on your inputs.
/// - Clearing `raw` (setting it to `nil`) before encoding can produce minimal outputs when round‑tripping
///   is not required.
///
/// See also:
/// - `OneOrMany` — wrapper that models either a single value or an array of values.
/// - `AnyCodable` — an `Encodable`/`Decodable` type‑erased box used to preserve the original payload.
/// - `RawCodable` — a protocol indicating the type can retain and re‑emit its raw representation.

/// Coding keys used to decode and encode the subset of fields modeled by `DefaultIdentifiableAndTypeObject`.
/// - `id`: The object's unique identifier key in the payload.
/// - `type`: The object's classification key, which may be a single string or an array of strings.

/// The unique identifier extracted from the decoded payload and used to satisfy `Identifiable.id`.

/// The object's type value(s).
/// - Uses `OneOrMany<String>` so payloads may specify either:
///   - a single type string, or
///   - an array of type strings.

/// The original, unparsed payload captured during decoding.
/// - If present, encoding will write this value verbatim, preserving all fields (including those
///   not explicitly modeled by this type).
/// - If `nil`, encoding falls back to emitting only `id` and `type`.

/// Creates a new instance with the provided identifier, type(s), and optional raw payload.
/// - Parameters:
///   - id: The unique identifier.
///   - type: A single type or an array of types for the object.
///   - raw: Optional original payload to preserve for round‑tripping. If omitted, only `id` and `type` are encoded.

/// Decodes an instance by extracting `id` and `type`, and stores the entire payload in `raw` for lossless round‑tripping.
/// - Parameter decoder: The decoder to read data from.
/// - Throws: A decoding error if `id` or `type` are missing or of an unexpected shape.

/// Encodes the instance.
/// - If `raw` is present, it is encoded verbatim to preserve the original payload.
/// - Otherwise, only the `id` and `type` fields are encoded.
/// - Parameter encoder: The encoder to write data to.
/// - Throws: An encoding error if encoding fails.
public struct DefaultIdentifiableAndTypeObject: Identifiable, RawCodable {

    public enum CodingKeys: String, CodingKey {
        case id
        case type
    }

    /// The object's unique identifier.
    /// - Extracted from the "id" field during decoding.
    /// - Used to satisfy `Identifiable.id`.
    /// - When round‑tripping with a preserved `raw` payload, this value is emitted unchanged.
    public var id: String

    /// The object's classification value(s).
    ///
    /// Stored as `OneOrMany<String>` so the payload can express either a single type string
    /// (for example, `"Book"`) or an array of type strings (for example, `["Book", "Ebook"]`).
    ///
    /// Behavior:
    /// - Decoding: Read from the `"type"` key; accepts both a single string and an array of strings.
    /// - Encoding: If `raw` is `nil`, this value is written back to the `"type"` key, preserving the
    ///   single/array shape as represented by `OneOrMany`.
    /// - Ordering: When multiple values are provided, their order is preserved.
    ///
    /// Example:
    /// ```swift
    /// // Single type
    /// // { "type": "Book" }
    ///
    /// // Multiple types
    /// // { "type": ["Book", "Ebook"] }
    /// ```
    ///
    /// See also: `OneOrMany`
    public var type: OneOrMany<String>

    public var raw: AnyCodable?

    /// Creates a new value with an identifier, one or more type tags, and an optional
    /// preserved raw payload for lossless round‑tripping.
    /// 
    /// Use this when you already know the object's `id` and `type(s)` and optionally want to
    /// carry the original, unmodeled payload alongside them. If you provide `raw`, subsequent
    /// encoding will prefer to emit that payload verbatim; if `raw` is `nil`, only `id` and
    /// `type` are encoded.
    /// 
    /// - Parameters:
    ///   - id: The object's unique identifier, corresponding to the `"id"` field in the payload.
    ///   - type: The object's classification value(s). Use `OneOrMany<String>` to represent either a
    ///           single type string (e.g., `"Book"`) or an array of types (e.g., `["Book", "Ebook"]`).
    ///   - raw: The original, unparsed payload to preserve for round‑tripping. Pass `nil` to omit and
    ///          produce minimal encodings that include only `id` and `type`.
    /// 
    /// - Important: If `raw` is non‑`nil`, `encode(to:)` will write the `raw` payload unchanged and
    ///              will not synthesize a new object from `id` and `type`. Ensure the `id` and `type`
    ///              you supply are consistent with the contents of `raw` if you plan to round‑trip.
    /// 
    /// - SeeAlso: `OneOrMany`, `AnyCodable`, `RawCodable`.
    /// 
    /// - Example:
    ///   ```swift
    ///   // Single type
    ///   let book = DefaultIdentifiableAndTypeObject(
    ///       id: "123",
    ///       type: .one("Book")
    ///   )
    /// 
    ///   // Multiple types
    ///   let ebook = DefaultIdentifiableAndTypeObject(
    ///       id: "456",
    ///       type: .many(["Book", "Ebook"])
    ///   )
    /// 
    ///   // With preserved raw payload for lossless round‑trip
    ///   let rawPayload: AnyCodable = ["id": "789", "type": "Book", "title": "Swift Patterns"]
    ///   let roundTrippable = DefaultIdentifiableAndTypeObject(
    ///       id: "789",
    ///       type: .one("Book"),
    ///       raw: rawPayload
    ///   )
    ///   ```
    public init (id: String, type: OneOrMany<String>, raw: AnyCodable? = nil) {
        self.id = id
        self.type = type
        self.raw = raw
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.type = try container.decode(OneOrMany<String>.self, forKey: .type)
        self.raw = try AnyCodable(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        guard let raw else {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(type, forKey: .type)
            return
        }
        try raw.encode(to: encoder)
    }
}

