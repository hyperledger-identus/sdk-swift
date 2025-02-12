import Domain
import Foundation
import JSONWebKey
import JSONWebToken
import JSONWebSignature

struct PrismJWTCredentialPlugin: CredentialPlugin {
    let credentialType = "prismJWT"
    var version: String { jwtPlugin.version }
    var supportedOperations: [String] { jwtPlugin.supportedOperations }
    private let jwtPlugin = JWTCredentialPlugin()

    func createCredential(_ credentialData: Data) async throws -> Credential {
        try await jwtPlugin.createCredential(credentialData)
    }
    
    func credential(_ imported: Data) async throws -> Credential {
        try await jwtPlugin.credential(imported)
    }

    func requiredOptions(operation: String) -> [Domain.CredentialOperationsOptions] {
        jwtPlugin.requiredOptions(operation: operation)
    }

    func operation(
        type: String,
        format: String?,
        payload: Data?,
        options: [Domain.CredentialOperationsOptions]
    ) async throws -> Domain.OperationResult {
        try await jwtPlugin.operation(
            type: type,
            format: format,
            payload: payload,
            options: options
        )
    }
}
