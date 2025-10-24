import Domain
import Foundation

/// A helper type responsible for validating input claims intended to be issued as a W3C Verifiable Credential (VC).
///
/// `W3CIssueCredential` ensures that the provided claims can be encoded and decoded into a
/// `DefaultVerifiableCredential` and that they reference the correct W3C Verifiable Credentials v2.0 context.
/// This validation happens during initialization via `verifyClaims()`.
///
/// Usage:
/// - Initialize with `InputClaim` that represents the credential payload to be issued.
/// - The initializer throws if the claims do not conform to the expected W3C VC v2.0 structure.
///
/// Behavior:
/// - Encodes the raw `claims.value` using a normalized `JSONEncoder`.
/// - Decodes the result into a `DefaultVerifiableCredential` using a normalized `JSONDecoder`.
/// - Verifies that the credential’s `@context` array contains `W3CRegisteredConstants.verifiableCredential2_0Context`.
///
/// Errors:
/// - Throws `W3CIssueCredential.W3CIssuingCredentialError.contextIsNotW3CredentialsV2` if the `@context`
///   does not include the required W3C VC v2.0 context.
///
/// Dependencies:
/// - `InputClaim`: The input container for the credential claims. Must expose a `value` suitable for JSON encoding.
/// - `DefaultVerifiableCredential`: A decodable representation of a W3C Verifiable Credential.
/// - `JSONEncoder.normalized` / `JSONDecoder.normalized`: Project-specific normalized JSON coders used to ensure
///   stable encoding/decoding for verification.
/// - `W3CRegisteredConstants.verifiableCredential2_0Context`: The canonical v2.0 context URI to validate against.
///
/// Thread-safety:
/// - This type is a value type with immutable properties after initialization. It performs no shared mutable state access.
///
/// Example:
/// ```swift
/// // let input = InputClaim(value: yourCredentialDictionary)
/// // let issuer = try W3CIssueCredential(claims: input)
/// // If initialization succeeds, the claims are valid for W3C VC v2.0 issuance.
/// ```
///
/// - Note: This type does not perform cryptographic signing or issuance; it only validates that the
///   claims are structurally compatible with W3C Verifiable Credentials v2.0.
public struct W3CIssueCredential {
    /// Errors that can occur while validating claims for a W3C Verifiable Credential.
    ///
    /// - Note: These errors are surfaced by the initializer or `verifyClaims()` when the
    ///   provided `claims` cannot be validated against the W3C Verifiable Credentials v2.0 requirements.
    public enum W3CIssuingCredentialError: LocalizedError {
        case contextIsNotW3CredentialsV2
    }
    
    /// The original input claims to be issued as a W3C Verifiable Credential.
    ///
    /// This value is encoded and validated during initialization to ensure the payload
    /// matches the expected structure and includes the W3C VC v2.0 context.
    public let claims: InputClaim

    /// Creates a new validator for the provided claims and immediately verifies them.
    ///
    /// - Parameter claims: The credential payload to validate for issuance.
    /// - Throws: ``W3CIssueCredential/W3CIssuingCredentialError`` if the claims cannot be
    ///   encoded/decoded into a `DefaultVerifiableCredential` or if the W3C VC v2.0 context
    ///   is not present.
    public init(claims: InputClaim) throws {
        self.claims = claims

        try verifyClaims()
    }

    /// Verifies the `claims` by round-tripping through normalized JSON and checking the required context.
    ///
    /// The method:
    /// - Encodes `claims.value` using `JSONEncoder.normalized`.
    /// - Decodes the result into `DefaultVerifiableCredential` using `JSONDecoder.normalized`.
    /// - Confirms the credential `@context` contains `W3CRegisteredConstants.verifiableCredential2_0Context`.
    ///
    /// - Throws: ``W3CIssueCredential/W3CIssuingCredentialError/contextIsNotW3CredentialsV2`` if the
    ///   W3C Verifiable Credentials v2.0 context is missing.
    func verifyClaims() throws {
        let encoded = try JSONEncoder.normalized.encode(claims.value)
        let credential = try JSONDecoder.normalized.decode(DefaultVerifiableCredential.self, from: encoded)
        guard credential.context.array.contains(W3CRegisteredConstants.verifiableCredential2_0Context) else {
            throw W3CIssuingCredentialError.contextIsNotW3CredentialsV2
        }
    }
}

