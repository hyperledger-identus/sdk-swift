import Foundation

/// `ProofableCredential` is a protocol that adds provability functionality to a credential.
public protocol ProvableCredential {
    /// Creates a presentation proof for a request message with the given options.
    ///
    /// - Parameters:
    ///   - request: The request message for which the proof needs to be created.
    ///   - options: The options to use when creating the proof.
    /// - Returns: The proof as a `String`.
    /// - Throws: If there is an error creating the proof.
    func presentation(type: String, requestPayload: Data, options: [CredentialOperationsOptions]) async throws -> String

    /// Validates if the credential can be used for the given presentation request, using the specified options.
    ///
    /// - Parameters:
    ///   - request: The presentation request message to be validated against.
    ///   - options: Options that may influence the validation process.
    /// - Returns: A Boolean indicating whether the credential is valid for the presentation (`true`) or not (`false`).
    /// - Throws: If there is an error during the validation process.
    func isValidForPresentation(type: String, requestPayload: Data, options: [CredentialOperationsOptions]) throws -> Bool
}

public extension Credential {
    /// A Boolean value indicating whether the credential is proofable.
    var isProofable: Bool { self is ProvableCredential }

    /// Returns the proofable representation of the credential.
    var proof: ProvableCredential? { self as? ProvableCredential }
}
