import Foundation

/// A claim type that encapsulates a `Date` value for use in verifiable or structured data payloads.
///
/// `DateClaim` conforms to `InputClaim` and wraps a `ClaimElement` whose underlying element
/// is a codable `Date`. This allows date-based information to be included consistently in
/// claims collections with optional disclosure semantics.
///
/// Usage:
/// - Initialize with a claim key and a `Date` value to produce a standardized claim.
/// - Optionally mark the claim as `disclosable` to indicate whether the value may be selectively revealed.
///
/// Example:
/// ```swift
/// let createdAt = Date()
/// let claim = DateClaim(key: "created_at", value: createdAt, disclosable: true)
/// ```
///
/// - Note: The `value` property stores the internal `ClaimElement` representation,
///         where the element is `.codable(Date)`.
///
/// - SeeAlso: `InputClaim`, `ClaimElement`
public struct DateClaim: InputClaim {
    public var value: ClaimElement

    /// Initializes a `DateClaim` with a key and a date value.
    /// - Parameters:
    ///   - key: The key for the claim.
    ///   - value: The date value for the claim.
    public init(key: String, value: Date, disclosable: Bool = false) {
        self.value = ClaimElement(key: key, element: .codable(value), disclosable: disclosable)
    }
}
