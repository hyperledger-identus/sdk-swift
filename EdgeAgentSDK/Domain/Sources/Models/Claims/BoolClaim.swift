import Foundation

/// A simple input claim wrapper for Boolean values.
///
/// `BoolClaim` conforms to `InputClaim` and encapsulates a single `Bool` value
/// associated with a key, packaged as a `ClaimElement`. It is intended for use
/// in systems that collect, disclose, or transmit typed claims as key/value
/// pairs.
///
/// Usage:
/// - Initialize with a key and a `Bool` to create a claim that can be fed into
///   a broader claims pipeline.
/// - Optionally mark the claim as `disclosable` to indicate whether the value
///   can be shared externally.
///
/// Example:
/// ```swift
/// let acceptsTerms = BoolClaim(key: "accepts_terms", value: true, disclosable: true)
/// ```
///
/// - SeeAlso: `InputClaim`, `ClaimElement`
public struct BoolClaim: InputClaim {
    public var value: ClaimElement
    
    /// Initializes a `BoolClaim` with a key and a boolean value.
    /// - Parameters:
    ///   - key: The key for the claim.
    ///   - value: The boolean value for the claim.
    public init(key: String, value: Bool, disclosable: Bool = false) {
        self.value = ClaimElement(key: key, element: .codable(value), disclosable: disclosable)
    }
}
