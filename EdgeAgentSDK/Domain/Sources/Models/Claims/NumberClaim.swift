import Foundation

/// A claim type used to represent numeric values within a structured claim system.
///
/// NumberClaim wraps a numeric value conforming to both `Numeric` and `Codable`
/// and stores it as a `ClaimElement` for use in claim-based payloads or requests.
/// It is useful when you need to assert or transmit numeric attributes (e.g.,
/// ages, counts, identifiers) in a consistent, serializable format.
///
/// Usage example:
/// ```swift
/// let ageClaim = NumberClaim(key: "age", value: 30)
/// let scoreClaim = NumberClaim(key: "score", value: 98.6, disclosable: true)
/// ```
///
/// - Note: The numeric type you provide (e.g., `Int`, `Double`, `Decimal` if Codable)
///   must conform to both `Numeric` and `Codable`. Standard Swift numeric types such as
///   `Int`, `UInt`, `Float`, and `Double` are supported.
///
/// - SeeAlso: `InputClaim`, `ClaimElement`
public struct NumberClaim: InputClaim {
    public var value: ClaimElement
    
    /// Initializes a `NumberClaim` with a key and a numeric value.
    /// - Parameters:
    ///   - key: The key for the claim.
    ///   - value: The numeric value for the claim.
    public init<N: Numeric & Codable>(key: String, value: N, disclosable: Bool = false) {
        self.value = ClaimElement(key: key, element: .codable(value), disclosable: disclosable)
    }
}
