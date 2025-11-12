import Domain
import Foundation

/// A concrete input claim representing the W3C Verifiable Credentials `validFrom` field.
///
/// This claim encapsulates the date and time at which a credential becomes valid,
/// adhering to the W3C Verifiable Credentials Data Model. It wraps the provided
/// `Date` into a `ClaimElement` with the key `"validFrom"` so it can be serialized
/// and transported as part of a credential issuance or presentation flow.
///
/// Usage:
/// - Initialize with a `Date` indicating when the credential should start being considered valid.
/// - Optionally mark the claim as `disclosable` to control selective disclosure behavior,
///   if supported by the surrounding protocol or presentation mechanism.
///
/// Behavior:
/// - The `value` property stores the claim as a `ClaimElement` using a codable representation
///   of the provided `Date`.
/// - The key used for this claim is `"validFrom"`, consistent with W3C VC conventions.
///
/// - Note: The exact serialization format of `Date` (e.g., ISO 8601) depends on the
///   implementation of `ClaimElement` and its `.codable` encoding.
///
/// - Parameters:
///   - value: The date and time from which the credential is considered valid.
///   - disclosable: A flag indicating whether this claim can be selectively disclosed. Defaults to `false`.
///
/// - SeeAlso:
///   - W3C Verifiable Credentials Data Model: Validity fields such as `validFrom` and `validUntil`.
public struct W3CValidFromClaim: InputClaim {
    public var value: ClaimElement

    public init(value: Date, disclosable: Bool = false) {
        self.value = ClaimElement(key: "validFrom", element: .codable(value), disclosable: disclosable)
    }
}
