import Domain
import Foundation

/// A Verifiable Credential issuer claim tailored for W3C data models.
///
/// `W3CIssuerClaim` represents the `issuer` field in a W3C Verifiable Credential.
/// It can be constructed in two ways:
/// - As a string identifier (e.g., a DID or URL) using `init(id:disclosable:)`.
/// - As an object with multiple properties using the result-builder initializer
///   `init(issuer:disclosable:)`, which enforces that an `"id"` field is present.
///
/// Conformance:
/// - Conforms to `InputClaim`, enabling composition within claim builders.
/// - Wraps its content in a `ClaimElement` under the key `"issuer"`.
///
/// Disclosure:
/// - The `disclosable` flag propagates to the underlying `ClaimElement`, allowing selective
///   disclosure strategies if supported by the consuming protocol.
///
/// Initialization:
/// - `init(id:disclosable:)`:
///   Creates an issuer claim with a simple string identifier.
/// - `init(issuer:disclosable:)`:
///   Creates an issuer claim as an object. This initializer validates that the provided
///   claims contain an `"id"` field with a non-nil `String` value. If the `"id"` field
///   is absent or invalid, it throws `IssuerRequiresIDField`.
///
/// Validation:
/// - `IssuerRequiresIDField`:
///   A localized error thrown when the object-based initializer is used without an `"id"`
///   property, or when the `"id"` property's value cannot be read as a `String`.
///
/// Usage examples:
/// - Minimal string-based issuer:
///   - `try W3CIssuerClaim(id: "did:example:123")`
/// - Object-based issuer with required `id` plus additional attributes:
///   - `try W3CIssuerClaim { StringClaim(key: "id", value: "did:example:123"); StringClaim(key: "name", value: "Acme Corp") }`
///     (Note: actual claim types must conform to `InputClaim` and produce a key `"id"` for the identifier.)
///
/// Notes:
/// - The object-based initializer uses `@ObjectClaimBuilder` to aggregate nested claims into
///   an issuer object. Ensure that one of the nested claims produces a value whose key is `"id"`
///   and whose value is a `String`.
/// - The exact types `InputClaim`, `ClaimElement`, `Value`, and `@ObjectClaimBuilder` are provided
///   by the surrounding domain model and are expected to support key/value composition and extraction.
public struct W3CIssuerClaim: InputClaim {

    /// An error indicating that the W3C issuer object is missing a required "id" field.
    ///
    /// This error is thrown by the object-based initializer of `W3CIssuerClaim` when the
    /// constructed issuer object does not include a valid `"id"` key with a `String` value.
    /// The `"id"` field is mandatory for W3C Verifiable Credential issuer objects.
    ///
    /// Typical causes:
    /// - No claim producing the `"id"` key was included in the issuer object builder.
    /// - The `"id"` key exists but its value is not a `String` or is `nil`.
    ///
    /// Recovery:
    /// - Ensure the issuer object includes an `"id"` claim with a non-empty `String` value,
    ///   for example by adding an appropriate claim type that sets the `"id"` field.
    ///
    /// Localized description:
    /// - Provides a user-readable message describing the missing or invalid `"id"` field.
    public struct IssuerRequiresIDField: LocalizedError {
        public var errorDescription: String? = "The IssuerClaim requires an ID field."
    }

    /// The wrapped claim element representing the issuer.
    ///
    /// This property stores the underlying `ClaimElement` constructed by the
    /// initializers. Its `key` is always `"issuer"`, and its `element` contains
    /// either a string identifier or an object composed via `@ObjectClaimBuilder`.
    /// The `disclosable` flag is propagated here to enable selective disclosure
    /// strategies if supported by the consuming protocol.
    public var value: ClaimElement

    /// Creates an issuer claim from an object built with nested claims.
    ///
    /// Use this initializer when you want to provide a full issuer object with
    /// multiple properties (for example, `id`, `name`, and others). The builder
    /// must produce an `id` field whose value can be read as a non-`nil` `String`.
    /// If the `id` is missing or invalid, this initializer throws
    /// ``W3CIssuerClaim/IssuerRequiresIDField``.
    ///
    /// - Parameters:
    ///   - issuer: A result builder that aggregates nested `InputClaim`s into the
    ///     issuer object. One of the nested claims must provide the key `"id"` with
    ///     a `String` value.
    ///   - disclosable: Indicates whether the issuer object should be marked as
    ///     disclosable for selective disclosure strategies. Defaults to `false`.
    /// - Throws: ``W3CIssuerClaim/IssuerRequiresIDField`` if a valid `id` field is not present.
    public init(@ObjectClaimBuilder issuer: () -> [InputClaim], disclosable: Bool = false) throws {
        guard issuer().contains(where: {
                guard $0.value.key == "id" else { return false }
                let value: String? = $0.value.element.getValue()
                return value != nil
            }
        ) else {
            throw IssuerRequiresIDField()
        }
        self.value = .init(key: "issuer", element: Value.object(issuer().map(\.value)), disclosable: disclosable)
    }

    /// Creates an issuer claim using a simple string identifier.
    ///
    /// Use this convenience initializer when the issuer can be represented by a
    /// single identifier (such as a DID or URL). The identifier is stored under
    /// the `"issuer"` key as a string value.
    ///
    /// - Parameters:
    ///   - id: The issuer's string identifier (e.g., a DID or URL).
    ///   - disclosable: Indicates whether the issuer identifier should be marked as
    ///     disclosable for selective disclosure strategies. Defaults to `false`.
    public init(id: String, disclosable: Bool = false) {
        self.value = .init(key: "issuer", value: id, disclosable: disclosable)
    }
}
