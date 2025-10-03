import Domain
import Foundation
import JSONWebToken

extension LegacyJWTCredential: ProvableCredential {
    public func presentation(
        type: String,
        requestPayload: Data,
        options: [CredentialOperationsOptions]
    ) throws -> String {
        try LegacyJWTPresentation().createPresentation(
            credential: self,
            type: type,
            requestData: requestPayload,
            options: options
        )
    }

    public func isValidForPresentation(
        type: String,
        requestPayload: Data,
        options: [CredentialOperationsOptions]
    ) throws -> Bool {
        switch type {
        case "dif/presentation-exchange/definitions@v1.0":
            let requestData = try JSONDecoder.didComm().decode(PresentationExchangeRequest.self, from: requestPayload)
            let payload: Data = try JWT.getPayload(jwtString: jwtString)
            do {
                try requestData.presentationDefinition.inputDescriptors.forEach {
                    try VerifyJsonClaim.verify(inputDescriptor: $0, jsonData: payload)
                }
                return true
            } catch {
                return false
            }
        case "prism/jwt", "jwt":
            return true
        default:
            throw PolluxError.unsupportedAttachmentFormat(type)
        }
    }
}
