import Domain

/// A claim representing the W3C Verifiable Credential `type` field.
///
/// This type builds a `ClaimElement` for the `type` key in a W3C Verifiable Credential,
/// ensuring that the W3C-registered base type appears first, followed by any additional,
/// user-provided types in sorted order. It also supports marking the claim as disclosable.
///
/// Behavior:
/// - Ensures the base W3C type (`W3CRegisteredConstants.verifiableCredentialType`) is included exactly once.
/// - Removes duplicates of the base type from the provided set to avoid repetition.
/// - Produces an ordered array where the base type is first, followed by sorted additional types.
/// - Wraps each type as a `ClaimElement` within an array claim.
/// - Supports selective disclosure via the `disclosable` flag.
///
/// Requirements:
/// - Conforms to `InputClaim`.
/// - Depends on `ClaimElement` and `W3CRegisteredConstants` from the `Domain` module.
///
/// Initialization:
/// - `init(strings: Set<String> = Set(), disclosable: Bool = false)`
///   - `strings`: A set of additional type strings to include alongside the base W3C type.
///   - `disclosable`: Whether the overall `type` claim is disclosable.
///
/// Example:
/// - Given `strings = ["UniversityDegreeCredential", "AlumniCredential"]`,
///   the resulting `type` array will be:
///   `[ "VerifiableCredential", "AlumniCredential", "UniversityDegreeCredential" ]`
///   where `"VerifiableCredential"` is the registered base type.
public struct W3CTypeClaim: InputClaim {
    /// The constructed claim element representing the W3C Verifiable Credential `type` field.
    /// 
    /// This value is an array claim where:
    /// - The first element is the W3C-registered base type (`"VerifiableCredential"`).
    /// - Subsequent elements are user-provided additional types, sorted alphabetically and
    ///   guaranteed not to duplicate the base type.
    /// - Each array entry is wrapped as a `ClaimElement` with an empty key and `disclosable` set to `false`.
    ///
    /// The overall array claim inherits the `disclosable` behavior specified during initialization,
    /// enabling selective disclosure of the entire `type` array if desired.
    public var value: ClaimElement

    /// Initializes a W3CTypeClaim for the W3C Verifiable Credential `type` field.
    /// 
    /// This initializer constructs a `ClaimElement` representing the `type` claim as an array,
    /// ensuring the W3C-registered base type (`"VerifiableCredential"`) is present exactly once,
    /// followed by any additional, user-supplied types in sorted order. Duplicate occurrences of
    /// the base type in `strings` are removed to avoid repetition.
    ///
    /// - Parameters:
    ///   - strings: A set of additional type identifiers to include alongside the base W3C type.
    ///              Any occurrence of the registered base type is ignored to prevent duplication.
    ///              The resulting additional types are sorted alphabetically in the output array.
    ///   - disclosable: A Boolean value indicating whether the entire `type` array claim is
    ///                  selectively disclosable. Defaults to `false`.
    ///
    /// - Important: The resulting `ClaimElement` is an array where:
    ///   - The first element is the registered base type (`"VerifiableCredential"`).
    ///   - Subsequent elements are the sorted contents of `strings` after removing the base type.
    ///   - Each array entry is wrapped as a `ClaimElement` with an empty key and `disclosable` set to `false`,
    ///     while the top-level array inherits the `disclosable` value provided here.
    ///
    /// - SeeAlso: `W3CRegisteredConstants.verifiableCredentialType`, `ClaimElement`, `InputClaim`
    public init(strings: Set<String> = Set(), disclosable: Bool = false) {
        var contextsSet = strings
        contextsSet.remove(W3CRegisteredConstants.verifiableCredentialType)
        let contexts = [W3CRegisteredConstants.verifiableCredentialType] + contextsSet.sorted()
        self.value = .init(
            key: "type",
            element: .array(contexts.map { ClaimElement(key: "", value: $0, disclosable: false) }) ,
            disclosable: disclosable
        )
    }
}
