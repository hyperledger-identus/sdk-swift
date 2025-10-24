import Domain
import Foundation

/// A builder-friendly claim wrapper for the W3C Verifiable Credential `credentialSubject` field.
///
/// Use `W3CCredentialSubjectClaim` when constructing the `credentialSubject` portion of a
/// Verifiable Credential. It supports both array and object forms via dedicated result
/// builder initializers, and allows marking the claim as disclosable.
///
/// Overview:
/// - The `credentialSubject` is a required top-level property in W3C Verifiable Credentials.
/// - This type conforms to `InputClaim` so it can participate in higher-level claim builders.
/// - Internally it stores a `ClaimElement` with the key set to `"credentialSubject"`.
///
/// Usage:
/// - Use the array initializer when your `credentialSubject` should be an array of claims.
/// - Use the object initializer when your `credentialSubject` should be a single object composed of claims.
/// - The `disclosable` flag controls whether the claim can be selectively disclosed.
///
/// Initializers:
/// - `init(subjects:disclosable:)`
///   - Parameters:
///     - subjects: An array claim builder returning a list of `InputClaim` elements to be wrapped as an array.
///     - disclosable: Indicates whether this claim supports selective disclosure. Defaults to `false`.
///
/// - `init(subject:disclosable:)`
///   - Parameters:
///     - subject: An object claim builder returning a list of `InputClaim` elements to be wrapped as an object.
///     - disclosable: Indicates whether this claim supports selective disclosure. Defaults to `false`.
///
/// Dependencies:
/// - `InputClaim`: Protocol that this type conforms to, representing a claim input in the building process.
/// - `ClaimElement`: Concrete value container used to hold the key/value pair for the claim.
/// - `ArrayClaimBuilder` and `ObjectClaimBuilder`: Result builders that aggregate nested `InputClaim`s.
///
/// Notes:
/// - The key is fixed to `"credentialSubject"` to align with the W3C VC data model.
/// - The builder closures are evaluated immediately and transformed into the appropriate `ClaimElement`
///   representation (`.array` or `.object`).
/// - Ensure that the nested `InputClaim`s provided by the builders produce valid `ClaimElement`s expected
///   by your credential schema.
///
/// Example (object):
/// ```swift
/// W3CCredentialSubjectClaim(disclosable: true) {
///     W3CNameClaim("Alice")
///     W3CAgeClaim(28)
/// }
/// ```
///
/// Example (array):
/// ```swift
/// W3CCredentialSubjectClaim(disclosable: false) {
///     W3CSubjectEntryClaim(id: "did:example:123")
///     W3CSubjectEntryClaim(id: "did:example:456")
/// }
/// ```
public struct W3CCredentialSubjectClaim: InputClaim {
    public var value: ClaimElement

    public init(@ArrayClaimBuilder subjects: () -> [InputClaim], disclosable: Bool = false) {
        self.value = .init(key: "credentialSubject", element: .array(subjects().map(\.value)), disclosable: disclosable)
    }

    public init(@ObjectClaimBuilder subject: () -> [InputClaim], disclosable: Bool = false) {
        self.value = .init(key: "credentialSubject", element: .object(subject().map(\.value)), disclosable: disclosable)
    }
}
