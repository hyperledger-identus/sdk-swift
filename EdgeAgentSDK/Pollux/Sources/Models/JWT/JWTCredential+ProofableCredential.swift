import Domain
import Foundation
import JSONWebToken

extension JWTCredential: ProvableCredential {
    public func presentation(type: String, requestPayload: Data, options: [CredentialOperationsOptions]) async throws -> String {
        try JWTCreatePresentation().createPresentation(
            credential: self,
            type: type,
            requestData: requestPayload,
            options: options
        )
    }

    public func isValidForPresentation(type: String, requestPayload: Data, options: [Domain.CredentialOperationsOptions]) throws -> Bool {
        switch type {
        case "dif/presentation-exchange/definitions@v1.0":
            let requestData = try JSONDecoder.didComm().decode(PresentationExchangeRequest.self, from: requestPayload)
            let payload: Data = try JWT.getPayload(jwtString: jwtString)
            guard
                let format = requestData.presentationDefinition.format?.jwt
            else {
                return false
            }
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
