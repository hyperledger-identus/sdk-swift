import Foundation

/// A claim type that represents a JSON array within a larger claims structure.
///
/// `ArrayClaim` is used to model an array value for a given key in a claim-based
/// payload. It leverages result builders to concisely construct arrays of elements,
/// where each element can be a primitive (string, number, boolean), another array,
/// or an object. The resulting array is wrapped as a `ClaimElement` and associated
/// with the provided key.
///
/// This type offers two convenience initializers:
/// - One that accepts a builder producing `[ArrayElementClaim]`, ideal when you want
///   to explicitly construct array elements using the typed helpers like
///   `ArrayElementClaim.string(_:)`, `.number(_:)`, `.bool(_:)`, `.array {}`, and
///   `.object {}`.
/// - One that accepts a builder producing `[InputClaim]`, which is useful for arrays
///   directly composed of other claim types conforming to `InputClaim`.
///
/// The `disclosable` flag can be used to indicate whether the array (and its elements,
/// depending on your surrounding logic) may be disclosed in contexts like logs or
/// debug output.
///
/// Example usage with `ArrayElementClaim`:
/// ```swift
/// let claim = ArrayClaim(key: "items") {
///     ArrayElementClaim.string("apple")
///     ArrayElementClaim.number(42)
///     ArrayElementClaim.bool(true)
///     ArrayElementClaim.array {
///         ArrayElementClaim.string("nested")
///     }
///     ArrayElementClaim.object {
///         StringClaim(key: "name", value: "widget")
///         NumberClaim(key: "count", value: 3)
///     }
/// }
/// ```
///
/// Example usage with `[InputClaim]`:
/// ```swift
/// let claim = ArrayClaim(key: "objects") {
///     ObjectClaim {
///         StringClaim(key: "id", value: "123")
///     }
///     ObjectClaim {
///         StringClaim(key: "id", value: "456")
///     }
/// }
/// ```
///
/// - SeeAlso: `ArrayElementClaim`, `ObjectClaim`, `StringClaim`, `NumberClaim`, `BoolClaim`, `InputClaim`, `ClaimElement`
public struct ArrayClaim: InputClaim {
    public var value: ClaimElement

    /// Initializes an `ArrayClaim` with a key and a builder for the array elements.
    /// - Parameters:
    ///   - key: The key for the claim.
    ///   - claims: A closure that returns an array of `ArrayElementClaim` using the result builder.
    public init(key: String, disclosable: Bool = false, @ArrayClaimBuilder claims: () -> [InputClaim]) {
        self.value = .init(key: key, element: .array(claims().map(\.value)), disclosable: disclosable)
    }
}

/// Represents an element within an array claim.
public struct ArrayValueClaim {
    let value: InputClaim

    public init<T: InputClaim>(_ value: T) {
        self.value = value
    }

    /// Creates an `ArrayElementClaim` with a string value.
    /// - Parameter str: The string value for the claim.
    /// - Returns: An `ArrayElementClaim` containing the string value.
    public static func string(_ str: String, disclosable: Bool = false) -> ArrayValueClaim {
        .init(StringClaim(key: "", value: str, disclosable: disclosable))
    }

    /// Creates an `ArrayElementClaim` with a numeric value.
    /// - Parameter number: The numeric value for the claim.
    /// - Returns: An `ArrayElementClaim` containing the numeric value.
    public static func number<N: Numeric & Codable>(_ number: N, disclosable: Bool = false) -> ArrayValueClaim {
        .init(NumberClaim(key: "", value: number, disclosable: disclosable))
    }

    /// Creates an `ArrayElementClaim` with a boolean value.
    /// - Parameter boolean: The boolean value for the claim.
    /// - Returns: An `ArrayElementClaim` containing the boolean value.
    public static func bool(_ boolean: Bool, disclosable: Bool = false) -> ArrayValueClaim {
        .init(BoolClaim(key: "", value: boolean, disclosable: disclosable))
    }

    /// Creates an `ArrayElementClaim` with an array of claims.
    /// - Parameter claims: A closure that returns an array of `ArrayElementClaim` using the result builder.
    /// - Returns: An `ArrayElementClaim` containing the array of claims.
    public static func array(@ArrayClaimBuilder claims: () -> [InputClaim], disclosable: Bool = false) -> ArrayValueClaim {
        .init(ArrayClaim(key: "", disclosable: disclosable, claims: claims))
    }

    /// Creates an `ArrayElementClaim` with an object of claims.
    /// - Parameter claims: A closure that returns an array of `Claim` using the result builder.
    /// - Returns: An `ArrayElementClaim` containing the object of claims.
    public static func object(@ObjectClaimBuilder claims: () -> [InputClaim], disclosable: Bool = false) -> ArrayValueClaim {
        .init(ObjectClaim(key: "", disclosable: disclosable, claims: claims))
    }

    /// Creates an `ArrayElementClaim` with a string value.
    /// - Parameter claim: The InputClaim value for the claim.
    /// - Returns: An `ArrayElementClaim` containing the string value.
    public static func claim<T: InputClaim>(_ claim: T) -> ArrayValueClaim {
        .init(claim)
    }
}
