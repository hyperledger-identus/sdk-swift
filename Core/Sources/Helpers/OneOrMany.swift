/// A utility enum that models values which may appear as either a single item or an array of items,
/// commonly seen in JSON APIs that are not schema-consistent.
/// 
/// `OneOrMany` normalizes access to such values while preserving the original shape when re-encoding.
/// Use the `array` property to always work with `[T]`, regardless of whether the source was a single
/// value or an array.
///
/// - Generic Parameter:
///   - T: The element type. Must conform to `RawCodable`.
///
/// - Conforms To:
///   - `RawCodable` (and, by extension, `Codable` if `RawCodable` refines it)
///
/// - Decoding Behavior:
///   - Attempts to decode an array `[T]` first. If that fails, falls back to decoding a single `T`.
///   - This means that if both `[T]` and `T` could plausibly decode from the same payload, the array
///     form wins.
///   - `null` is not accepted; use `OneOrMany<T>?` if the field can be `null` or omitted.
///
/// - Encoding Behavior:
///   - Preserves shape: `.one` encodes as a single `T`; `.many` encodes as `[T]`.
///
/// - Normalization:
///   - Use `array` to always obtain `[T]` for iteration and higher-level logic.
///
/// - Bridging:
///   - The `raw` property exposes an `AnyCodable` representation of the wrapped value(s), satisfying
///     `RawCodable` requirements.
///
/// - Use Cases:
///   - Fields like `"tag": "swift"` vs `"tag": ["swift", "ios"]`
///
/// - Examples:
///   ```swift
///   struct Response: Codable {
///       let tags: OneOrMany<Tag>
///   }
///
///   // JSON: { "tags": "swift" }
///   // -> Response.tags == .one(Tag("swift"))
///   // -> Response.tags.array == [Tag("swift")]
///
///   // JSON: { "tags": ["swift", "ios"] }
///   // -> Response.tags == .many([Tag("swift"), Tag("ios")])
///   // -> Response.tags.array == [Tag("swift"), Tag("ios")]
///
///   // Encoding preserves shape:
///   // OneOrMany.one(Tag("swift"))  -> "swift"
///   // OneOrMany.many([Tag("swift"), Tag("ios")]) -> ["swift", "ios"]
///   ```
///
/// - See Also:
///   - `RawCodable`
///   - `AnyCodable`
///
///
/// Case: `.one`
/// Wraps a single value of type `T`.
///
///
/// Case: `.many`
/// Wraps multiple values as an array `[T]`.
///
///
/// Property: `array`
/// A normalized view of the contents as `[T]`.
/// - If the receiver is `.one(v)`, returns `[v]`.
/// - If the receiver is `.many(vs)`, returns `vs` unchanged.
///
///
/// Property: `raw`
/// The `RawCodable` raw representation as `AnyCodable`, mirroring the underlying shape:
/// - For `.one(v)`, returns `AnyCodable(v)`.
/// - For `.many(vs)`, returns `AnyCodable(vs)`.
///
///
/// Initializer: `init(from:)`
/// Decodes the value from a single-value container, preferring arrays.
/// - Parameters:
///   - decoder: The decoder to read data from.
/// - Throws: An error if neither `[T]` nor `T` can be decoded from the payload.
///
///
/// Method: `encode(to:)`
/// Encodes the value into a single-value container, preserving shape.
/// - Parameters:
///   - encoder: The encoder to write data to.
/// - Throws: An error if encoding fails.
public enum OneOrMany<T: Codable>: RawCodable {
    case one(T)
    case many([T])

    /// A normalized view of the wrapped value(s) as an array.
    /// 
    /// This property allows you to work with the contents uniformly as `[T]`,
    /// regardless of whether the underlying representation is a single value
    /// (`.one`) or an array (`.many`).
    ///
    /// Behavior:
    /// - If the receiver is `.one(value)`, returns `[value]`.
    /// - If the receiver is `.many(values)`, returns `values` unchanged.
    ///
    /// Notes:
    /// - Order and duplicates are preserved.
    /// - This is a computed convenience; accessing it does not mutate the enum.
    /// - If you need to preserve the original shape for re-encoding, use the enum
    ///   cases directly; `array` is only for normalized access.
    ///
    /// Example:
    /// ```swift
    /// switch tags.array {
    /// case []:
    ///     // no tags
    /// default:
    ///     // iterate uniformly over tags
    ///     for tag in tags.array { /* ... */ }
    /// }
    /// ```
    public var array: [T] {
        switch self {
        case .one(let v): return [v]
        case .many(let v): return v
        }
    }

    public var raw: AnyCodable? {
        switch self {
        case .one(let v): return .init(v)
        case .many(let v): return .init(v)
        }
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()

        if let many = try? c.decode([T].self) {
            self = .many(many)
            return
        }

        self = .one(try c.decode(T.self))
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .one(let v): try c.encode(v)
        case .many(let v): try c.encode(v)
        }
    }
}
