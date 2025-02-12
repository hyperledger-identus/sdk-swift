import Domain
import Foundation
import JSONWebKey
import JSONWebToken
import JSONWebSignature

struct JWTCredentialPlugin: CredentialPlugin {
    let version = "0.1"
    let credentialType = "jwt"
    let supportedOperations = [
        "offer",
        "offer-credential",
        "issue",
        "issue-credential"
    ]

    func requiredOptions(operation: String) -> [Domain.CredentialOperationsOptions] {
        []
    }

    func operation(
        type: String,
        format: String?,
        payload: Data?,
        options: [Domain.CredentialOperationsOptions]
    ) async throws -> Domain.OperationResult {
        guard let payload else { throw PolluxError.invalidJWTCredential }
        switch type {
        case "offer", "offer-credential":
            let processedJWTCredentialRequest = try await processJWTCredentialRequest(
                offerData: payload,
                options: options
            )
            return try .forward(
                type: "request-credential",
                format: format,
                payload: processedJWTCredentialRequest.tryToData()
            )
        case "issue", "issue-credential":
            return try await .credential(createCredential(payload))
        default:
            throw PolluxError.unsupportedIssuedMessage
        }
    }

    func createCredential(_ credentialData: Data) async throws -> Credential {
        try JWTCredential(data: credentialData)
    }
    
    func credential(_ imported: Data) async throws -> Credential {
        try JWTCredential(data: imported)
    }

    private func processJWTCredentialRequest(offerData: Data, options: [CredentialOperationsOptions]) async throws -> String {
        guard
            let subjectDIDOption = options.first(where: {
                if case .subjectDID = $0 { return true }
                return false
            }),
            case let CredentialOperationsOptions.subjectDID(did) = subjectDIDOption
        else {
            throw PolluxError.invalidPrismDID
        }

        guard
            let exportableKeyOption = options.first(where: {
                if case .exportableKey = $0 { return true }
                return false
            }),
            case let CredentialOperationsOptions.exportableKey(exportableKey) = exportableKeyOption
        else {
            throw PolluxError.requiresExportableKeyForOperation(operation: "Create Credential Request")
        }

        return try await CreateJWTCredentialRequest.create(didStr: did.string, key: exportableKey, offerData: offerData)
    }
}
