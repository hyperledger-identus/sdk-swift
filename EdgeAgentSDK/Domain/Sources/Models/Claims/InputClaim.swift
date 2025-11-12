import Foundation

/// A recursive enumeration that represents the different kinds of values that can be used
/// within an input claim. This type allows for flexible composition of claim data, including
/// primitive codable values, nested elements, arrays, and objects.
///
/// The `Value` enum is marked as `indirect` to enable recursive structures, such as arrays
/// and objects containing other `ClaimElement` instances, which themselves can contain `Value`s.
///
/// Cases:
/// - `codable(Codable)`: Wraps any value conforming to `Codable`, suitable for primitives or
///   custom types that can be encoded/decoded. This is useful for simple claim values like
///   strings, numbers, booleans, or codable structs.
/// - `element(ClaimElement)`: Represents a single nested claim element, allowing for hierarchical
///   claim composition.
/// - `array([ClaimElement])`: Represents an ordered collection of claim elements, useful when a
///   claim contains a list of structured items.
/// - `object([ClaimElement])`: Represents a dictionary-like structure composed of named claim
///   elements, suitable for complex, nested data models.
///
/// Usage notes:
/// - Prefer `codable` for simple values to leverage Swift's `Codable` ecosystem.
/// - Use `element`, `array`, and `object` to model nested and composite data structures.
/// - The recursive nature of `Value` enables building arbitrarily deep structures while keeping
///   a uniform representation across different claim shapes.
public indirect enum Value {
    /// A primitive or custom value that conforms to `Codable`.
    /// Use for strings, numbers, booleans, dates, or any codable struct/class.
    case codable(Codable)

    /// A single nested claim element, enabling hierarchical composition.
    case element(ClaimElement)

    /// An ordered collection of claim elements, representing a list.
    case array([ClaimElement])

    /// A dictionary-like grouping of named claim elements, representing a structured object.
    case object([ClaimElement])
}

/// A protocol that defines a unified interface for input claims used in the claims system.
///
/// Conforming types represent a single claim that can be provided as input, such as a primitive
/// value, a nested element, an array of elements, or an object composed of elements. Each input
/// claim exposes its content via a `ClaimElement`, which includes:
/// - a `key` that identifies the claim,
/// - an `element` that describes the value using the recursive `Value` enum,
/// - and a `disclosable` flag indicating whether the claim may be disclosed.
///
/// Usage:
/// - Adopt `InputClaim` in types that encapsulate a claim to be submitted or processed.
/// - Provide the `value` property to fully describe the claim's structure and disclosure policy.
/// - Use the `ClaimElement` convenience initializers to wrap codable values or compose nested data.
///
/// Example:
/// - A simple string claim can wrap a `.codable` value.
/// - A complex claim can be an `.object` or `.array` of nested `ClaimElement`s.
///
/// Concurrency and serialization:
/// - The `value` ultimately relies on `ClaimElement` and `Value`, enabling composition and potential
///   encoding/decoding strategies by consumers of this protocol.
///
/// See also:
/// - `ClaimElement` for the container of a claim's key, value, and disclosure policy.
/// - `Value` for the recursive representation of underlying claim data.
public protocol InputClaim {
    var value: ClaimElement { get }
}

/// A container that represents a single named piece of claim data.
///
/// ClaimElement combines three pieces of information:
/// - key: A stable identifier (field name) for the claim value.
/// - element: The underlying value, expressed using the recursive `Value` enum,
///   which supports codable primitives, nested elements, arrays, and objects.
/// - disclosable: A flag indicating whether this element may be revealed to
///   third parties or included in disclosures.
///
/// Use this type to build structured claim payloads of arbitrary complexity by:
/// - Wrapping simple values with the `init(key:value:disclosable:)` convenience
///   initializer, which stores them as `.codable`.
/// - Composing nested structures via `.element`, `.array`, or `.object` in `Value`.
///
/// Example use cases:
/// - A primitive attribute (e.g., "givenName": "Ada") with disclosable = true.
/// - A nested object (e.g., "address") composed of multiple sub-elements.
/// - An array of items (e.g., "credentials") where each item is a `ClaimElement`.
///
/// Notes:
/// - The `key` should be unique within its containing object or array context.
/// - `disclosable` allows policy-driven filtering of elements before sharing.
/// - Because `Value` is `indirect`, deep and recursive structures are supported.
///
/// See also:
/// - `Value` for supported value shapes.
/// - `InputClaim` for types that expose a single `ClaimElement` as their value.
public struct ClaimElement {
    /// A stable identifier (field name) for this claim element within its container.
    public let key: String

    /// The underlying value for the claim, represented using the recursive `Value` enum.
    public let element: Value

    /// Indicates whether this element may be disclosed to third parties.
    public let disclosable: Bool

    /// Creates a new claim element with a key, a value, and a disclosure policy.
    /// - Parameters:
    ///   - key: The stable identifier (field name) for this claim element.
    ///   - element: The underlying value wrapped in the recursive `Value` enum.
    ///   - disclosable: Whether this element may be disclosed to third parties.
    public init(key: String, element: Value, disclosable: Bool) {
        self.key = key
        self.element = element
        self.disclosable = disclosable
    }

    /// Convenience initializer for wrapping a `Codable` value.
    /// Stores the provided value as `.codable` in the underlying `Value` enum.
    /// - Parameters:
    ///   - key: The stable identifier (field name) for this claim element.
    ///   - value: A value conforming to `Codable` that will be wrapped as `.codable`.
    ///   - disclosable: Whether this element may be disclosed to third parties.
    public init<C: Codable>(key: String, value: C, disclosable: Bool) {
        self.key = key
        self.element = .codable(value)
        self.disclosable = disclosable
    }
}

