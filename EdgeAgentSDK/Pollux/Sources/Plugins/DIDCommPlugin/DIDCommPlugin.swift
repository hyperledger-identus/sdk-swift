import Domain
import Foundation

struct DIDCommPlugin: ProtocolPlugin {
    let version: String = "0.1"
    let supportedOperations: [String] = [
        "https://didcomm.org/issue-credential/3.0/offer-credential",
        "https://didcomm.org/issue-credential/3.0/issue-credential"
    ]
    var supportedCredentialTypes: [String] {
        credentialPlugins.map(\.credentialType)
    }
    private let supportProtocols: [ProtocolPlugin]
    private let credentialPlugins: [CredentialPlugin]

    func requiredOptions(operation: String) -> [Domain.CredentialOperationsOptions] {
        []
    }
    func operation(
        type: String,
        format: String?,
        payload: Data?,
        options: [Domain.CredentialOperationsOptions]
    ) async throws -> Domain.OperationResult {
        guard let format else { throw PolluxError.unsupportedIssuedMessage }
        switch type {
        case "https://didcomm.org/issue-credential/3.0/offer-credential":
            guard
                let supportProtocol = supportProtocols
                    .first(where: {
                        $0.supportedOperations.contains("offer-credential") && $0.supportedCredentialTypes.contains(format)
                    })
            else {
                throw PolluxError.unsupportedIssuedMessage
            }
            return try await supportProtocol.operation(
                type: "offer-credential",
                format: format,
                payload: payload,
                options: options
            )
        case "https://didcomm.org/issue-credential/3.0/issue-credential":
            guard
                let supportProtocol = supportProtocols
                    .first(where: {
                        $0.supportedOperations.contains("issue-credential")
                        && $0.supportedCredentialTypes.contains(format)
                    })
            else {
                throw PolluxError.unsupportedIssuedMessage
            }
            return try await supportProtocol.operation(
                type: "issue-credential",
                format: format,
                payload: payload,
                options: options
            )
        default:
            return .verification(verified: false)
        }
    }
}
