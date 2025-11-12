import Foundation

/// A composite claim that represents a JSON-like object composed of nested claims.
///
/// ObjectClaim groups multiple child claims under a single key, producing a hierarchical
/// object structure. It conforms to `InputClaim` and wraps its data in a `ClaimElement`.
/// This type is typically constructed via the `@ObjectClaimBuilder` result builder,
/// allowing a clean, declarative syntax for assembling nested claims.
///
/// Usage:
/// - Create a named object with nested claims using the `init(key:claims:disclosable:)`.
/// - Internally, claims are converted into `ClaimElement` values and aggregated as an `.object`.
///
/// Key characteristics:
/// - `isRoot`: Indicates whether the claim is acting as the root object.
/// - `value`: The underlying `ClaimElement` representation of the object claim.
/// - `disclosable`: Optional flag indicating whether the object can be disclosed.
///
/// Initialization options:
/// - `init(key: @ObjectClaimBuilder claims:disclosable:)`:
///   Builds an object claim for the specified key using the result builder to supply child claims.
/// - Internal initializers exist for constructing from raw `ClaimElement` arrays or for creating
///   a root-level object without a key.
///
/// Dependencies:
/// - `InputClaim`: Protocol conformance for claim input types.
/// - `ClaimElement`: Encapsulates the claim’s key, element kind, and disclosure settings.
/// - `@ObjectClaimBuilder`: Result builder used to declare nested claims succinctly.
///
/// Typical example:
/// - Create a user object with nested fields like name, email, and address,
///   where each field is a claim and the parent is an ObjectClaim keyed by "user".
///
/// Thread-safety:
/// - `ObjectClaim` is a value type (`struct`) and is generally safe to pass across
///   concurrency boundaries, assuming its members are value-safe.
///
/// Note:
/// - Only the public initializer with the result builder is intended for general use.
///   Other initializers are internal and support framework composition details.
public struct ObjectClaim: InputClaim {
    let isRoot: Bool
    public var value: ClaimElement
    
    /// Initializes an `ObjectClaim` with a key and a builder for the object elements.
    /// - Parameters:
    ///   - key: The key for the claim.
    ///   - claims: A closure that returns an array of `Claim` using the result builder.
    public init(key: String, disclosable: Bool = false, @ObjectClaimBuilder claims: () -> [InputClaim]) {
        self.isRoot = false
        self.value = .init(key: key, element: .object(claims().map(\.value)), disclosable: disclosable)
    }
    
    init(key: String, claims: [ClaimElement], disclosable: Bool = false) {
        self.isRoot = false
        self.value = .init(key: key, element: .object(claims), disclosable: disclosable)
    }
    
    init(root: Bool, claims: [ClaimElement], disclosable: Bool = false) {
        self.isRoot = root
        self.value = .init(key: "", element: .object(claims), disclosable: disclosable)
    }
}
