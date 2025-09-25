import Core
import Foundation

/// A lightweight, generic representation of an identifiable object that preserves
/// its original, unmodeled payload for round‑tripping and later introspection.
///
/// DefaultIdentifiableObject is useful when:
/// - You only need a stable identifier (id) and, optionally, a type field.
/// - You want to keep the full, original payload around to re‑encode it later,
///   even if your model does not have typed properties for all fields.
/// - You are working with heterogeneous objects that may vary in structure over time.
///
/// Conformances:
/// - Identifiable: Exposes `id` as the stable identifier.
/// - RawCodable: Retains the raw, decoded payload (via `AnyCodable`) to enable
///   lossless re‑encoding and ad‑hoc inspection.
///
/// Encoding/Decoding behavior:
/// - On decoding, `id` and (optionally) `type` are decoded into properties,
///   and the entire payload is captured into `raw`.
/// - On encoding, if `raw` is present, it is encoded verbatim, ensuring
///   lossless round‑tripping. If `raw` is nil, only `id` and `type` are encoded.
///   Note that when `type` is nil, the current implementation encodes it as
///   a JSON null rather than omitting the key.
///
/// Thread safety:
/// - This is a value type (struct). Mutations require explicit copies.
///
/// See also:
/// - RawCodable
/// - AnyCodable
/// - OneOrMany
///
/// Example
/// ```swift
/// // Decoding an object while preserving unknown fields:
/// let object = try JSONDecoder().decode(DefaultIdentifiableObject.self, from: data)
/// print(object.id)          // Stable identifier
/// print(object.type)        // One or many type names, if present
/// print(object.raw)         // Full original payload
///
/// // Re-encoding preserves the original payload if `raw` is set:
/// let roundTripped = try JSONEncoder().encode(object)
/// ```

/// The coding keys supported by DefaultIdentifiableObject.
/// - id: The stable identifier for the object.
/// - type: An optional type or list of types associated with the object.

/// A globally unique identifier for the object.
/// This is mapped from the "id" field in the encoded payload.

/// Optional type information for the object, supporting one or many values.
/// This is mapped from the "type" field in the encoded payload.
/// - Note: Uses `OneOrMany<String>` to allow either a single type name or an array of type names.

/// The raw, unmodeled representation of the entire decoded payload.
/// If present, this will be used verbatim during encoding to ensure lossless round‑tripping.
/// - Important: When `raw` is non‑nil, `encode(to:)` ignores the `id` and `type`
///   properties and writes `raw` instead.

/// Creates a new DefaultIdentifiableObject.
/// - Parameters:
///   - id: The stable identifier for the object.
///   - type: Optional type(s) associated with the object.
///   - raw: An optional raw representation of the full payload. If provided,
///          it will be used verbatim during encoding.

/// Creates a new instance by decoding from the given decoder.
/// - Parameter decoder: The decoder to read data from.
/// - Throws: An error if decoding fails or if the required `id` field is missing.
/// - Note: This initializer decodes `id` and (optionally) `type`, and also
///         captures the entire payload into `raw` for lossless round‑tripping.

/// Encodes this value into the given encoder.
/// - Parameter encoder: The encoder to write data to.
/// - Throws: An error if any values fail to encode.
/// - Important: If `raw` is non‑nil, it is encoded verbatim. Otherwise, only
///              `id` and `type` are encoded. With the current implementation,
///              a nil `type` is encoded as a JSON null rather than omitting the key.
public struct DefaultIdentifiableObject: Identifiable, RawCodable {

    public enum CodingKeys: String, CodingKey {
        case id
        case type
    }
    
    /// A stable, globally unique identifier for this object.
    ///
    /// - Mapping: Reads from and writes to the "id" field in the encoded payload (`CodingKeys.id`).
    /// - Conformance: Satisfies `Identifiable.id`.
    /// - Encoding behavior: If `raw` is non‑nil, `encode(to:)` serializes `raw` verbatim and
    ///   this value is ignored. Clear `raw` to ensure this `id` is written during encoding.
    public var id: String

    /// Optional type information for the object.
    /// - Mapping: Reads from and writes to the "type" field in the encoded payload (`CodingKeys.type`).
    /// - Shape: Uses `OneOrMany<String>` so it can be either a single type name or an array of type names.
    /// - Typical uses: Disambiguating heterogeneous object kinds, filtering, or routing.
    /// - Decoding: Missing "type" decodes as `nil`. Accepts either a single string or an array of strings.
    /// - Encoding: When `raw` is `nil`, this value is encoded as-is; with the current implementation a `nil` value is encoded as JSON null rather than omitting the key. When `raw` is non‑nil, `encode(to:)` serializes `raw` verbatim and this value is ignored.
    /// - See also: `OneOrMany`
    public var type: OneOrMany<String>?
    public var raw: AnyCodable?

    /// Creates a new lightweight, identifiable object while optionally preserving an
    /// unmodeled, raw payload for lossless round‑tripping.
    /// 
    /// Use this initializer when:
    /// - You only need a stable `id` and, optionally, a `type` (single or multiple).
    /// - You want to keep the original, untyped payload (`raw`) so it can be re‑encoded
    ///   later exactly as it was received.
    /// - You are working with heterogeneous objects whose structure may change over time.
    /// 
    /// - Parameters:
    ///   - id: The stable, globally unique identifier for the object.
    ///   - type: Optional type information for the object. Uses `OneOrMany<String>` so it
    ///           can be either a single type name or an array of type names. Defaults to `nil`.
    ///   - raw: An optional unmodeled representation of the full payload (`AnyCodable`).
    ///          If provided, it will be used verbatim during encoding to ensure lossless
    ///          round‑tripping. Defaults to `nil`.
    /// 
    /// - Important: When `raw` is non‑nil, `encode(to:)` writes `raw` verbatim and
    ///   ignores the `id` and `type` properties. Clear `raw` to ensure changes to
    ///   `id` and `type` are reflected during encoding.
    /// 
    /// - See also:
    ///   - `RawCodable`
    ///   - `AnyCodable`
    ///   - `OneOrMany`
    /// 
    /// - Example:
    /// ```swift
    /// // A simple object with a single type
    /// let a = DefaultIdentifiableObject(id: "123", type: .one("User"))
    /// 
    /// // An object with multiple types
    /// let b = DefaultIdentifiableObject(id: "456", type: .many(["User", "Admin"]))
    /// 
    /// // Preserve the original payload for round‑tripping
    /// let payload: AnyCodable = ["id": "789", "type": "User", "unknown": 42]
    /// let c = DefaultIdentifiableObject(id: "789", type: .one("User"), raw: payload)
    /// // Encoding `c` will serialize `payload` exactly as provided.
    /// ```
    public init (id: String, type: OneOrMany<String>? = nil, raw: AnyCodable? = nil) {
        self.id = id
        self.type = type
        self.raw = raw
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.type = try container.decodeIfPresent(OneOrMany<String>.self, forKey: .type)
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
