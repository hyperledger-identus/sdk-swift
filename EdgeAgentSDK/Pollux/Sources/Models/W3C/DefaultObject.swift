import Core
import Foundation

/// A lightweight, forward‑compatible container for loosely‑typed JSON objects that
/// preserves the original payload while surfacing common fields.
///
/// DefaultObject is designed for scenarios where you need to:
/// - Safely decode and retain an entire JSON payload you may not fully model yet.
/// - Access a few well‑known fields (such as `id` and `type`) without losing the rest.
/// - Re‑encode the object either as the original raw payload or as a minimal, normalized form.
///
/// Overview
/// - On decode:
///   - `id` and `type` are decoded if present.
///   - The entire source payload is captured in `raw` as `AnyCodable`, so you never lose unknown fields.
/// - On encode:
///   - If `raw` is non‑nil, the object is emitted exactly as the original raw payload (verbatim passthrough).
///   - If `raw` is nil, only the normalized fields (`id` and `type`) are encoded.
///
/// This behavior lets you round‑trip unknown or evolving schemas without data loss, while still enabling
/// light introspection via `id` and `type`.
///
/// Properties
/// - id: An optional identifier pulled from the payload, if present.
/// - type: An optional type or list of types (using `OneOrMany<String>`) pulled from the payload, if present.
/// - raw: The full, type‑erased source payload (`AnyCodable`). When present, it is used verbatim on re‑encoding.
///
/// Encoding and Decoding Details
/// - Decoding:
///   - `id` is decoded from the `"id"` key if present.
///   - `type` is decoded from the `"type"` key and supports either a single string or an array of strings via `OneOrMany<String>`.
///   - `raw` captures the entire payload so that unknown fields and structure are retained.
/// - Encoding:
///   - If `raw` is set, it is encoded as‑is, ignoring `id` and `type`.
///   - If `raw` is nil, only `id` and `type` are emitted, producing a minimal, normalized representation.
///
/// Important
/// If you mutate `id` or `type` after decoding, those changes will NOT be reflected when encoding if `raw` is still set,
/// because encoding prefers the original `raw` payload. To emit your normalized changes:
/// - Set `raw = nil` before encoding, or
/// - Update `raw` to reflect your changes.
///
/// Typical Use Cases
/// - Pass‑through or proxy services that must preserve unknown fields when forwarding payloads.
/// - Gradual schema adoption where only a subset of fields are modeled initially.
/// - Logging, auditing, or inspection of complete payloads while still extracting common identifiers.
///
/// Example: Passthrough round‑trip
/// ```swift
/// // Decode unknown payload while extracting id/type
/// let object = try JSONDecoder().decode(DefaultObject.self, from: data)
/// print(object.id, object.type) // Optional values if present
///
/// // Re‑encode as the original payload (lossless)
/// let forwarded = try JSONEncoder().encode(object) // Uses `raw`
/// ```
///
/// Example: Emit only normalized fields
/// ```swift
/// var object = try JSONDecoder().decode(DefaultObject.self, from: data)
/// object.id = "new-id"
/// object.type = .one("CustomType")
/// object.raw = nil // Opt into normalized encoding
/// let minimal = try JSONEncoder().encode(object) // Encodes only id/type
/// ```
///
/// Related Types
/// - RawCodable: A protocol indicating the type carries a raw representation for passthrough encoding.
/// - AnyCodable: A type‑erased wrapper that can encode/decode arbitrary JSON structures.
/// - OneOrMany<String>: A helper that decodes either a single string or an array of strings under the same key.
///
/// Thread Safety
/// DefaultObject is a value type with no internal synchronization. Treat it as you would any other struct when
/// sharing across threads.
///
/// Performance Notes
/// Storing the entire payload in `raw` can increase memory usage for large objects. If you do not need to
/// preserve the original payload, set `raw = nil` to enable minimal encoding.
public struct DefaultObject: RawCodable {

    public enum CodingKeys: String, CodingKey {
        case id
        case type
    }
    
    /// An optional identifier for the object, sourced from the `"id"` key in the payload if present.
    /// - Decoding: Extracted from the `"id"` field when available.
    /// - Encoding:
    ///   - If `raw` is non-nil, this value is ignored because the original payload is emitted verbatim.
    ///   - If `raw` is nil, this value is encoded under the `"id"` key as part of the normalized representation.
    /// - Mutability: Changes made after decoding will not affect the encoded output unless you set `raw = nil`
    ///   (to opt into normalized encoding) or update `raw` to reflect the change.
    /// - See also: `type`, `raw`
    public var id: String?

    /// An optional type or list of types describing the object's semantic classification.
    /// - Type: Uses `OneOrMany<String>` so the `"type"` field can be either a single string
    ///   or an array of strings and will decode into a unified representation.
    /// - Decoding: Extracted from the `"type"` key if present. Supports both:
    ///   - `"type": "Example"`
    ///   - `"type": ["Example", "Another"]`
    /// - Encoding:
    ///   - If `raw` is non-nil, this value is ignored and the original payload is emitted verbatim.
    ///   - If `raw` is nil, this value is encoded under the `"type"` key as part of the normalized representation.
    /// - Mutability: Changes made after decoding will not affect the encoded output unless you set `raw = nil`
    ///   (to opt into normalized encoding) or update `raw` to reflect the change.
    /// - See also: `id`, `raw`, `OneOrMany`
    public var type: OneOrMany<String>?
    public var raw: AnyCodable?

    /// Initializes a new DefaultObject with optional normalized fields and an optional raw payload.
    /// 
    /// Use this initializer when you want to construct a DefaultObject either as:
    /// - A passthrough container that preserves the full original JSON payload (`raw`), or
    /// - A minimal, normalized object that only carries `id` and `type` (set `raw` to `nil`).
    ///
    /// Encoding behavior:
    /// - If `raw` is non-nil, the object will encode as the original payload verbatim (ignores `id` and `type`).
    /// - If `raw` is nil, the object will encode only the normalized fields (`id` and `type`).
    ///
    /// - Parameters:
    ///   - id: An optional identifier to associate with the object. Ignored on encoding if `raw` is provided.
    ///   - type: An optional type or list of types describing the object. Ignored on encoding if `raw` is provided.
    ///           Uses `OneOrMany<String>` to support either a single string or an array of strings.
    ///   - raw: The full, type-erased source payload to preserve for passthrough encoding. When provided, it is
    ///          used verbatim on re-encoding, ensuring lossless round-tripping of unknown fields.
    ///
    /// - Important: If you mutate `id` or `type` after initialization, those changes will not be reflected on encoding
    ///   while `raw` remains non-nil. To emit your normalized changes, set `raw = nil` before encoding or update `raw`
    ///   to match your changes.
    ///
    /// - Examples:
    ///   ```swift
    ///   // Minimal, normalized object (encodes only id/type)
    ///   let normalized = DefaultObject(id: "123", type: .one("Example"), raw: nil)
    ///
    ///   // Passthrough object that preserves the original payload (encodes verbatim)
    ///   let passthrough = DefaultObject(id: "123",
    ///                                   type: .many(["Example", "Another"]),
    ///                                   raw: AnyCodable(["id": "123", "type": ["Example", "Another"], "extra": 42]))
    ///   ```
    public init (id: String? = nil, type: OneOrMany<String>? = nil, raw: AnyCodable? = nil) {
        self.id = id
        self.type = type
        self.raw = raw
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
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
