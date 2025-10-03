import Foundation
import JSONWebToken

/// An error indicating that a `RawCodable` value does not have an underlying
/// raw representation available for decoding.
///
/// This error is thrown by `RawCodable.decodedAs(_:)` when the conforming
/// instance’s `raw` property is `nil`, meaning there is no source payload
/// from which to decode the requested `Decodable` type.
///
/// Typical causes:
/// - The conforming type did not supply a `raw` payload when it was created.
/// - The value was constructed or transformed in a way that discarded its raw representation.
///
/// Recovery suggestions:
/// - Ensure the `RawCodable` instance was initialized with a valid raw payload.
/// - If you control the conforming type, implement `raw` so it reflects the
///   underlying data you intend to decode.
/// - If you only have already-encoded data, decode directly from that data
///   instead of calling `decodedAs(_:)`.
///
/// Example:
/// ```swift
/// do {
///     let model: MyDecodable = try someRawCodable.decodedAs()
/// } catch is RawValueNotProvided {
///     // Handle the absence of a raw payload (e.g., show an error or fall back)
/// }
/// ```
///
/// - SeeAlso: `RawCodable`, `RawCodable.decodedAs(_:)`
public struct RawValueNotProvided: Error {}

/// A `Codable`-refining protocol for values that can expose (and be re‑decoded from)
/// an underlying, untyped raw representation.
///
/// `RawCodable` is useful when you want to:
/// - Carry around a strongly-typed model while preserving its original payload.
/// - Lazily decode different `Decodable` views of the same raw data.
/// - Round‑trip values without losing the source bytes (for logging, auditing, or
///   signature verification scenarios).
///
/// Conforming types provide:
/// - `raw`: an optional `AnyCodable` payload representing the underlying data.
/// - `decodedAs<T>()`: a convenience to decode that payload into any `Decodable` type.
///
/// If `raw` is `nil`, `decodedAs<T>()` throws `RawValueNotProvided`.
/// If decoding fails, any `DecodingError` produced by the decoder is propagated.
///
/// Example:
/// ```swift
/// struct User: Codable { let id: String; let name: String }
///
/// func makeUser(from source: some RawCodable) throws -> User {
///     // Infers T from context:
///     try source.decodedAs() as User
/// }
/// ```
///
/// Guidance for conformers:
/// - Prefer storing the original, lossless payload in `raw`.
/// - Ensure `raw` is consistent with your encoded representation so that decoding
///   the same model back from `raw` yields equivalent data.
/// - If you cannot provide a raw payload (e.g., the value was synthesized), set
///   `raw` to `nil` so callers can handle the absence explicitly.
///
/// Thread safety:
/// - `RawCodable` itself imposes no synchronization; if your `raw` storage is
///   mutable or shared, coordinate access appropriately.
///
/// - SeeAlso: `RawValueNotProvided`, `AnyCodable`
///
///
/// The underlying, untyped payload from which this value can be (re)decoded.
///
/// - Returns: An `AnyCodable` wrapping the original source representation, or `nil`
///   if no raw payload is available (e.g., the value was synthesized or the payload
///   was intentionally discarded).
///
/// Semantics:
/// - When non‑`nil`, `raw` should be a faithful representation of the data used to
///   construct the conforming value (or the data you intend to decode from).
/// - When `nil`, calls to `decodedAs(_:)` will throw `RawValueNotProvided`.
///
///
/// Decodes the underlying `raw` payload as the requested `Decodable` type.
///
/// - Returns: A value of type `T` decoded from the `raw` payload.
/// - Throws:
///   - `RawValueNotProvided` if `raw` is `nil`.
///   - Any `DecodingError` thrown while decoding `T` from the raw payload.
/// - Note: The generic type `T` can usually be inferred from context:
///   ```swift
///   let user: User = try rawValue.decodedAs()
///   ```
/// - Complexity: O(n) in the size of the raw payload.
public protocol RawCodable: Codable {
    var raw: AnyCodable? { get }
    func decodedAs<T: Decodable>(encoder: JSONEncoder, decoder: JSONDecoder) throws -> T
}

public extension RawCodable {
    /// Decodes this value’s underlying raw payload into the requested `Decodable` type,
    /// using the supplied JSON encoder/decoder pair.
    ///
    /// This method performs a two‑step round trip:
    /// 1. It serializes the `raw` payload (an `AnyCodable` wrapper) to `Data` using `encoder`.
    /// 2. It decodes that `Data` into `T` using `decoder`.
    ///
    /// Use this when you want to:
    /// - Materialize strongly‑typed views (`T`) over the same preserved raw payload.
    /// - Control decoding strategies (dates, keys, data) by providing custom encoder/decoder instances.
    /// - Ensure the decoded model reflects the original, lossless payload stored in `raw`.
    ///
    /// - Parameters:
    ///   - encoder: The `JSONEncoder` used to serialize the `raw` payload to `Data`.
    ///              Defaults to `.normalized`.
    ///   - decoder: The `JSONDecoder` used to decode the resulting `Data` into `T`.
    ///              Defaults to `.normalized`.
    ///
    /// - Returns: A value of type `T` decoded from the underlying `raw` payload.
    ///
    /// - Throws:
    ///   - `RawValueNotProvided` if `raw` is `nil` (no source payload available).
    ///   - Any `DecodingError` (or other error) thrown during encoding/decoding of the payload.
    ///
    /// - Important: The correctness of the result depends on `raw` faithfully representing the
    ///   data you intend to decode as `T`. If the payload and `T` do not match, decoding will fail.
    ///
    /// - Complexity: O(n) in the size of the raw payload, due to encoding then decoding.
    ///
    /// - Example:
    ///   ```swift
    ///   struct User: Decodable { let id: String; let name: String }
    ///
    ///   // Type inference:
    ///   let user: User = try rawValue.decodedAs()
    ///
    ///   // Custom strategies:
    ///   var decoder = JSONDecoder()
    ///   decoder.dateDecodingStrategy = .iso8601
    ///   let event: Event = try rawValue.decodedAs(decoder: decoder)
    ///   ```
    ///
    /// - SeeAlso: `RawCodable`, `RawValueNotProvided`, `AnyCodable`
    func decodedAs<T: Decodable>(encoder: JSONEncoder = .normalized, decoder: JSONDecoder = .normalized) throws -> T {
        guard let raw else { throw RawValueNotProvided() }
        let rawData = try encoder.encode(raw)
        return try decoder.decode(T.self, from: rawData)
    }
}

extension String: RawCodable {
    public var raw: AnyCodable? { .init(stringLiteral: self) }
}

extension Data: RawCodable {
    public var raw: AnyCodable? { .init(self) }
}

extension Int: RawCodable {
    public var raw: AnyCodable? { .init(self) }
}

extension Double: RawCodable {
    public var raw: AnyCodable? { .init(self) }
}

extension Float: RawCodable {
    public var raw: AnyCodable? { .init(self) }
}

extension Date: RawCodable {
    public var raw: AnyCodable? { .init(self) }
}
