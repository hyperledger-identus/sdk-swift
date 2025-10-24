import Domain
import Foundation

/// A claim representing the "validUntil" field in a W3C-compliant credential.
///
/// This claim encapsulates an expiration date for a credential, indicating the point in time
/// after which the credential should be considered invalid. It is modeled as an `InputClaim`
/// with an underlying `ClaimElement` whose key is `"validUntil"` and value is a `Date`
/// encoded as a codable element.
///
/// Usage:
/// - Initialize with a `Date` to specify the expiration timestamp.
/// - Optionally mark the claim as `disclosable` to indicate whether it can be selectively disclosed.
///
/// Parameters:
/// - value: The expiration date for the credential.
/// - disclosable: A Boolean indicating whether this claim can be selectively disclosed (default is `false`).
///
/// Dependencies:
/// - `InputClaim`: Protocol that this claim conforms to.
/// - `ClaimElement`: Type used to wrap the key/value/disclosability of the claim.
///
/// Example:
/// ```swift
/// let expiration = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
/// let claim = W3CValidUntilClaim(value: expiration, disclosable: true)
/// ```
public struct W3CValidUntilClaim: InputClaim {
    public var value: ClaimElement

    public init(value: Date, disclosable: Bool = false) {
        self.value = ClaimElement(key: "validUntil", element: .codable(value), disclosable: disclosable)
    }
}
