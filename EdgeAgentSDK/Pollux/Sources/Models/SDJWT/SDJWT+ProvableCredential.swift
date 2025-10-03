import Domain
import Foundation

extension SDJWTCredential: ProvableCredential {
    func presentation(request: Domain.Message, options: [Domain.CredentialOperationsOptions]) async throws -> String {
        guard
            let attachment = request.attachments.first,
            let format = attachment.format,
            let requestData = try request.attachments.first.flatMap({
                switch $0.data {
                case let json as AttachmentJsonData:
                    return try JSONEncoder.didComm().encode(json.json)
                case let bas64 as AttachmentBase64:
                    return Data(fromBase64URL: bas64.base64)
                default:
                    return nil
                }
            })
        else {
            throw PolluxError.offerDoesntProvideEnoughInformation
        }
        return try await SDJWTPresentation().createPresentation(
            credential: self,
            type: format,
            requestData: requestData,
            options: options
        )
    }

    func presentation(
        type: String,
        requestPayload: Data,
        options: [CredentialOperationsOptions]
    ) async throws -> String {
        try await SDJWTPresentation().createPresentation(
            credential: self,
            type: type,
            requestData: requestPayload,
            options: options
        )
    }

    func isValidForPresentation(request: Domain.Message, options: [Domain.CredentialOperationsOptions]) throws -> Bool {
        request.attachments.first.map { $0.format == "vc+sd-jwt"} ?? true
    }

    func isValidForPresentation(
        type: String,
        requestPayload: Data,
        options: [CredentialOperationsOptions]
    ) throws -> Bool {
        type == "vc+sd-jwt"
    }
}
