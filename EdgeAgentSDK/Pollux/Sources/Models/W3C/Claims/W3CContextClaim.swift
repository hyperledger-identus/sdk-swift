import Domain
import Foundation

/// A claim builder that produces a W3C Verifiable Credentials v2.0 compliant `@context` element.
///
/// This type conforms to `InputClaim` and encapsulates the construction of the `@context`
/// array for a Verifiable Credential. It ensures that the W3C-registered base context
/// (`https://www.w3.org/ns/credentials/v2`) is always present as the first element and
/// that any additional provided context URIs are included once, sorted, and without
/// duplicating the base context.
///
/// Initialization details:
/// - Accepts a set of context strings to include.
/// - Automatically removes the registered v2.0 base context from the provided set to prevent duplication.
/// - Produces an ordered array where the base context is first, followed by the sorted remaining contexts.
/// - Wraps the result in a `ClaimElement` with key `@context`, represented as an array of string elements,
///   each non-disclosable individually, with the overall claim's `disclosable` flag settable.
///
/// Parameters:
/// - strings: A set of additional context URIs to include alongside the W3C v2.0 base context.
/// - disclosable: Whether the `@context` claim as a whole is selectively disclosable (defaults to `false`).
///
/// Usage notes:
/// - The `value` property exposes the fully-formed `ClaimElement` for downstream processing or serialization.
/// - Individual items inside the `@context` array are marked non-disclosable; selective disclosure, if desired,
///   should be controlled via the `disclosable` parameter on the claim itself.
///
/// Dependencies:
/// - `InputClaim` protocol and `ClaimElement` type from the Domain module.
/// - `W3CRegisteredConstants.verifiableCredential2_0Context` for the canonical v2.0 base context URI.
public struct W3CV2ContextClaim: InputClaim {
    public var value: ClaimElement

    public init(strings: Set<String> = Set(), disclosable: Bool = false) {
        var contextsSet = strings
        contextsSet.remove(W3CRegisteredConstants.verifiableCredential2_0Context)
        let contexts = [W3CRegisteredConstants.verifiableCredential2_0Context] + contextsSet.sorted()
        self.value = .init(
            key: "@context",
            element: .array(contexts.map { ClaimElement(key: "", value: $0, disclosable: false) }) ,
            disclosable: disclosable
        )
    }
}
