import Core
import Domain
import Foundation

/// A claim builder for the W3C Verifiable Credential `credentialStatus` property.
///
/// This type provides multiple initializers to construct the `credentialStatus` claim
/// in compliance with the W3C Verifiable Credentials Data Model. It supports:
/// - A single status entry
/// - Multiple status entries
/// - A single object constructed via an `@ObjectClaimBuilder`
/// - An array of objects constructed via an `@ArrayClaimBuilder`
///
/// Key characteristics:
/// - The resulting claim is always keyed as `"credentialStatus"`.
/// - Each status object must include a `"type"` property, as required by the specification.
/// - When multiple status objects are provided, each object is validated for the presence of `"type"`.
///
/// Validation:
/// - If a credential status object does not contain a `"type"` property, a `CrentialStatusObjectRequiresType` error is thrown.
/// - If the provided structure cannot be interpreted as an object or array of objects with `"type"`, a `CrentialStatusMissmatchType` error is thrown.
///
/// Usage examples:
/// - Initialize with a single `StatusListEntry` to produce a single object claim.
/// - Initialize with `OneOrMany<StatusListEntry>` to produce either a single object or an array claim.
/// - Use `@ObjectClaimBuilder` to construct a single status object from multiple input claims.
/// - Use `@ArrayClaimBuilder` to construct an array of status objects, each validated to contain `"type"`.
///
/// Notes:
/// - The claim is marked as disclosable (`disclosable: true`), enabling selective disclosure in compatible protocols.
/// - Internally stores the constructed claim as a `ClaimElement` with an `element` of type `.object` or `.array`, depending on the initializer used.
///
/// Errors:
/// - `CrentialStatusObjectRequiresType`: Thrown when a status object is missing the required `"type"` property.
/// - `CrentialStatusMissmatchType`: Thrown when the provided status structure is not an object or array of objects, or when validation fails.
///
/// Conformance:
/// - Conforms to `InputClaim`, enabling composition with other claims and builders within the credential construction pipeline.
public struct W3CCredentialStatusClaim: InputClaim {

    public struct CrentialStatusObjectRequiresType: LocalizedError {
        public let errorDescription: String? = "A credential status object must contain a 'type' property."
    }

    public struct CrentialStatusMissmatchType: LocalizedError {
        public let errorDescription: String? = "A credential status should be an array of objects or a single object, all objects require a 'type' property."
    }

    /// The wrapped claim element representing the `credentialStatus` field.
    ///
    /// This property stores the underlying `ClaimElement` constructed by the
    /// initializers. Its `key` is always `"credentialStatus"`, and its `element`
    /// is either an object or an array of objects depending on the initializer used.
    /// The claim is marked as disclosable to support selective disclosure strategies.
    public var value: ClaimElement

    /// Creates a `credentialStatus` claim from one or many status list entries.
    ///
    /// Use this initializer when you already have concrete `StatusListEntry` values.
    /// If `statusEntry` is `.one`, the result is a single object claim; if it is `.many`,
    /// the result is an array claim where each entry becomes an object.
    ///
    /// - Parameter statusEntry: A single status list entry or a collection of entries.
    /// - Throws: An error if encoding the entries fails.
    public init(statusEntry: OneOrMany<StatusListEntry>) throws {
        switch statusEntry {
        case .one(let entry):
            self.value = .init(key: "credentialStatus", element: Value.codable(entry), disclosable: true)
        case .many(let array):
            let values = array.map { ClaimElement(key: "", value: $0, disclosable: true) }
            self.value = .init(key: "credentialStatus", element: Value.array(values), disclosable: true)
        }
    }

    /// Creates a `credentialStatus` claim from an array of status objects built via a result builder.
    ///
    /// Each built object is validated to contain a `"type"` property as required by the
    /// W3C Verifiable Credentials specification. If any object is missing `"type"`, this
    /// initializer throws ``W3CCredentialStatusClaim/CrentialStatusObjectRequiresType``.
    /// If the builder output cannot be interpreted as objects, it throws
    /// ``W3CCredentialStatusClaim/CrentialStatusMissmatchType``.
    ///
    /// - Parameter subjects: A result builder that produces an array of status objects.
    /// - Throws: ``W3CCredentialStatusClaim/CrentialStatusObjectRequiresType`` or
    ///   ``W3CCredentialStatusClaim/CrentialStatusMissmatchType`` when validation fails.
    public init(@ArrayClaimBuilder subjects: () -> [InputClaim]) throws {
        for subject in subjects() {
            let subjectClaims = subject.value.element.getObjectClaims()
            guard let subjectClaims else {
                throw CrentialStatusMissmatchType()
            }
            try validateCredentialStatusObject(claim: subjectClaims)
        }
        self.value = .init(key: "credentialStatus", element: .array(subjects().map(\.value)), disclosable: true)
    }

    /// Creates a `credentialStatus` claim from a single status object built via a result builder.
    ///
    /// The built object must include a `"type"` property. If the required property is
    /// missing, this initializer throws ``W3CCredentialStatusClaim/CrentialStatusObjectRequiresType``.
    ///
    /// - Parameter subject: A result builder that produces the properties of a single status object.
    /// - Throws: ``W3CCredentialStatusClaim/CrentialStatusObjectRequiresType`` when the object
    ///   does not include a required `"type"` property.
    public init(@ObjectClaimBuilder subject: () -> [InputClaim]) throws {
        let values = subject().map(\.value)
        try validateCredentialStatusObject(claim: values)
        self.value = .init(key: "credentialStatus", element: .object(values), disclosable: true)
    }
}

private func validateCredentialStatusObject(claim: [ClaimElement]) throws {
    guard claim.contains(where: { $0.key == "type" }) else { throw W3CCredentialStatusClaim.CrentialStatusObjectRequiresType() }
}
