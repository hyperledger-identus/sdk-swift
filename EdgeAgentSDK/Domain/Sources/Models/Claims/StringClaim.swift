import Foundation

/// A concrete claim type that encapsulates a string value for use in a claim-based payload.
/// 
/// StringClaim conforms to `InputClaim` and wraps its data in a `ClaimElement`,
/// allowing the value to be encoded/decoded and optionally marked as disclosable.
/// 
/// Usage:
/// - Initialize with a key and a string value to produce a claim that can be included
///   in input or disclosure flows.
/// - The `disclosable` flag indicates whether the claim can be selectively revealed.
///
/// Example:
/// ```swift
/// let usernameClaim = StringClaim(key: "username", value: "alice", disclosable: true)
/// ```
///
/// - SeeAlso: `InputClaim`, `ClaimElement`
public struct StringClaim: InputClaim {
    public var value: ClaimElement
    
    /// Initializes a `StringClaim` with a key and a string value.
    /// - Parameters:
    ///   - key: The key for the claim.
    ///   - value: The string value for the claim.
    public init(key: String = "", value: String, disclosable: Bool = false) {
        self.value = ClaimElement(key: key, element: .codable(value), disclosable: disclosable)
    }
}
