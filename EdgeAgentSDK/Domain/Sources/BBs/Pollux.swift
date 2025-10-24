import Combine
import Foundation

/// Options that can be passed into various operations.
public enum CredentialOperationsOptions {
    case schema(id: String, json: String)  // The JSON schema.
    case schemaDownloader(downloader: Downloader) // Stream of schemas, only the first batch is considered
    case credentialDefinition(id: String, json: String) // The JSON Credential Definition
    case credentialDefinitionDownloader(downloader: Downloader) // Download of credential definitions, only the first batch is considered
    case linkSecret(id: String, secret: String)  // A secret link.
    case subjectDID(DID)  // The decentralized identifier of the subject.
    case entropy(String)  // Entropy for any randomization operation.
    case signableKey(SignableKey)  // A key that can be used for signing.
    case privateKey(PrivateKey)  // A private key that can be used for signing.
    case exportableKey(ExportableKey)  // A key that can be exported.
    case exportableKeys([ExportableKey])  // A key that can be exported.
    case zkpPresentationParams(attributes: [String: Bool], predicates: [String]) // Anoncreds zero-knowledge proof presentation parameters
    case disclosingClaims(claims: [String])
    case thid(String)
    case presentationRequestId(String)
    case custom(key: String, data: Data)  // Any custom data.
}

/// The Pollux protocol defines a set of operations that are used in the Atala PRISM architecture.
public protocol Pollux {
    /// Parses an encoded item and returns an object representing the parsed item.
    /// - Parameter data: The encoded item to parse.
    /// - Throws: An error if the item cannot be parsed or decoded.
    /// - Returns: An object representing the parsed item.
    @available(*, deprecated, message: "Please use the new method for parseCredential(type: String, credentialPayload: Data, options: [CredentialOperationsOptions])")
    func parseCredential(issuedCredential: Message, options: [CredentialOperationsOptions]) async throws -> Credential

    /// Parses an encoded item and returns an object representing the parsed item.
    /// - Parameters:
    ///   - type: The type of the credential, (`jwt`, `prism/jwt`, `vc+sd-jwt`, `anoncreds`, `anoncreds/credential@v1.0`)
    ///   - credentialPayload: The encoded credential to parse.
    ///   - options: Options required for some types of credentials.
    /// - Throws: An error if the item cannot be parsed or decoded.
    /// - Returns: An object representing the parsed item.
    func parseCredential(type: String, credentialPayload: Data, options: [CredentialOperationsOptions]) async throws -> Credential

    /// Restores a previously stored item using the provided restoration identifier and data.
    /// - Parameters:
    ///   - restorationIdentifier: The identifier to use when restoring the item.
    ///   - credentialData: The data representing the stored item.
    /// - Throws: An error if the item cannot be restored.
    /// - Returns: An object representing the restored item.
    func restoreCredential(restorationIdentifier: String, credentialData: Data) throws -> Credential

    /// Processes a request based on a provided offer message and options.
    /// - Parameters:
    ///   - offerMessage: The offer message that contains the details of the request.
    ///   - options: The options to use when processing the request.
    /// - Throws: An error if the request cannot be processed.
    /// - Returns: A string representing the result of the request process.
    @available(*, deprecated, message: "Please use the new method for processCredentialRequest(type: String, offerPayload: Data, options: [CredentialOperationsOptions])")
    func processCredentialRequest(
        offerMessage: Message,
        options: [CredentialOperationsOptions]
    ) async throws -> String

    /// Processes a request based on a provided offer message and options.
    /// - Parameters:
    ///   - type: The type of the credential, (`jwt`, `prism/jwt`, `vc+sd-jwt`, `anoncreds`, `anoncreds/credential-offer@v1.0`)
    ///   - offerMessage: The offer message that contains the details of the request.
    ///   - options: The options to use when processing the request.
    /// - Throws: An error if the request cannot be processed.
    /// - Returns: A string representing the result of the request process.
    func processCredentialRequest(
        type: String,
        offerPayload: Data,
        options: [CredentialOperationsOptions]
    ) async throws -> String

    /// Creates a presentation request for credentials of a specified type, directed to a specific DID, with additional metadata and filtering options.
    ///
    /// - Parameters:
    ///   - type: The type of credential being requested (e.g., JWT, AnonCred).
    ///   - toDID: The decentralized identifier (DID) of the entity to which the presentation request is being sent.
    ///   - name: A descriptive name for the presentation request.
    ///   - version: The version of the presentation request format or protocol.
    ///   - claimFilters: A collection of filters specifying the claims required in the credential.
    /// - Returns: The serialized presentation request as `Data`.
    /// - Throws: An error if the request creation fails.
    func createPresentationRequest(
        type: CredentialType,
        toDID: DID,
        name: String,
        version: String,
        claimFilters: [ClaimFilter]
    ) throws -> Data

    /// Verifies the validity of a presentation contained within a message, using specified options.
    ///
    /// - Parameters:
    ///   - message: The message containing the presentation to be verified.
    ///   - options: An array of options that influence how the presentation verification is conducted.
    /// - Returns: A Boolean value indicating whether the presentation is valid (`true`) or not (`false`).
    /// - Throws: An error if there is a problem verifying the presentation.
    @available(*, deprecated, message: "Please use the new method for verifyPresentation(type: String, presentationPayload: Data, options: [CredentialOperationsOptions])")
    func verifyPresentation(
        message: Message,
        options: [CredentialOperationsOptions]
    ) async throws -> Bool

    /// Verifies the validity of a presentation contained within a message, using specified options.
    ///
    /// - Parameters:
    ///   - type: The type of the credential, (`jwt`, `prism/jwt`, `vc+sd-jwt`, `anoncreds`, `anoncreds/credential-presentation@v1.0`)
    ///   - presentationPayload: The message containing the presentation to be verified.
    ///   - options: An array of options that influence how the presentation verification is conducted.
    /// - Returns: A Boolean value indicating whether the presentation is valid (`true`) or not (`false`).
    /// - Throws: An error if there is a problem verifying the presentation.
    func verifyPresentation(
        type: String,
        presentationPayload: Data,
        options: [CredentialOperationsOptions]
    ) async throws -> Bool

    /// Issues a new verifiable credential of the specified type using the provided claims and options.
    /// 
    /// - Parameters:
    ///   - type: A string identifying the credential format to issue. Supported values typically include:
    ///     - "jwt", "vc+jwt" for JSON Web Token-based credentials
    ///     - "vc+sd-jwt" for selective disclosure JWT credentials
    ///     Implementations may support additional types; consult the concrete `Pollux` implementation.
    ///   - claims: A result-builder closure (`@CredentialClaimsBuilder`) that constructs the set of input claims
    ///     to be embedded or referenced in the credential. The structure and required fields depend on the `type`.
    ///   - options: A list of `CredentialOperationsOptions` providing contextual data and cryptographic material
    ///     required for issuance. Common options include:
    ///     - `.exportableKey(PrivateKey)` for signing
    ///     - `.linkSecret(id:secret:)` for AnonCreds link secret
    ///     - `.custom(key:data:)` for implementation-specific inputs
    ///
    /// - Returns: A `Credential` representing the issued verifiable credential, including any metadata necessary
    ///   for storage, presentation, or later verification.
    ///
    /// - Throws: An error if issuance fails due to invalid inputs, unsupported `type`, missing or incompatible
    ///   options (e.g., absent signing key, schema, or link secret), claim-building errors, or cryptographic failures.
    ///
    /// - Important:
    ///   - The exact combination of required `options` depends on the credential `type`.
    ///   - For formats requiring signing, you must provide a compatible key via one of the key-related options.
    ///   - When issuing AnonCreds credentials, schema and credential definition information, as well as a link secret,
    ///     are typically required.
    ///   - The `claims` closure should produce claims compatible with the selected `type`; mismatches may cause errors.
    ///
    /// - See Also:
    ///   - `parseCredential(type:credentialPayload:options:)`
    func issueCredential(
        type: String,
        @CredentialClaimsBuilder claims: () -> InputClaim,
        options: [CredentialOperationsOptions]
    ) async throws -> Credential
}

public extension Pollux {
    /// Restores a previously stored item using a `StorableCredential` instance.
    /// - Parameter storedCredential: The `StorableCredential` instance representing the stored item.
    /// - Throws: An error if the item cannot be restored.
    /// - Returns: An object representing the restored item.
    func restoreCredential(storedCredential: StorableCredential) throws -> Credential {
        try restoreCredential(
            restorationIdentifier: storedCredential.recoveryId,
            credentialData: storedCredential.credentialData
        )
    }
}
