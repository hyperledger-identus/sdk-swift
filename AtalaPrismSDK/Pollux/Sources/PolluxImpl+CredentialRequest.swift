import Domain
import Foundation
import JSONWebToken

extension PolluxImpl {
    
    private enum SupportedCredential: String {
        case jwt
        case anoncred
    }
    
    public func processCredentialRequest(
        offerMessage: Message,
        options: [CredentialOperationsOptions]
    ) async throws -> String {
        guard let offerAttachment = offerMessage.attachments.first else {
            throw PolluxError.offerDoesntProvideEnoughInformation
        }
        
        switch offerAttachment.format {
        case "jwt", "prism/jwt", .none:
            switch offerAttachment.data {
            case let json as AttachmentJsonData:
                return try processJWTCredentialRequest(offerData: json.data, options: options)
            default:
                throw PolluxError.offerDoesntProvideEnoughInformation
            }
        case "anoncreds/credential-offer@v1.0":
            switch offerAttachment.data {
            case let attachmentData as AttachmentJsonData:
                guard let thid = offerMessage.thid else {
                    throw PolluxError.messageDoesntProvideEnoughInformation
                }
                return try await processAnoncredsCredentialRequest(
                    offerData: attachmentData.data,
                    thid: thid,
                    options: options
                )
            case let attachmentData as AttachmentBase64:
                guard 
                    let thid = offerMessage.thid,
                    let data = Data(fromBase64URL: attachmentData.base64)
                else {
                    throw PolluxError.offerDoesntProvideEnoughInformation
                }
                return try await processAnoncredsCredentialRequest(
                    offerData: data,
                    thid: thid,
                    options: options
                )
            default:
                throw PolluxError.offerDoesntProvideEnoughInformation
            }
        default:
            break
        }
        throw PolluxError.invalidCredentialError
    }

    private func processJWTCredentialRequest(offerData: Data, options: [CredentialOperationsOptions]) throws -> String {
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
            case let CredentialOperationsOptions.exportableKey(exportableKey) = exportableKeyOption,
            let pemData = exportableKey.pem.data(using: .utf8)
        else {
            throw PolluxError.requiresExportableKeyForOperation(operation: "Create Credential Request")
        }
        
        return try CreateJWTCredentialRequest.create(didStr: did.string, key: exportableKey, offerData: offerData)
    }
    
    private func processAnoncredsCredentialRequest(
        offerData: Data,
        thid: String,
        options: [CredentialOperationsOptions]
    ) async throws -> String {
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
            let linkSecretOption = options.first(where: {
                if case .linkSecret = $0 { return true }
                return false
            }),
            case let CredentialOperationsOptions.linkSecret(linkSecretId, secret: linkSecret) = linkSecretOption
        else {
            throw PolluxError.invalidPrismDID
        }
        
        guard
            let credDefinitionDownloaderOption = options.first(where: {
                if case .credentialDefinitionDownloader = $0 { return true }
                return false
            }),
            case let CredentialOperationsOptions.credentialDefinitionDownloader(downloader) = credDefinitionDownloaderOption
        else {
            throw PolluxError.invalidPrismDID
        }
        
        return try await CreateAnoncredCredentialRequest.create(
            did: did.string,
            linkSecret: linkSecret,
            linkSecretId: linkSecretId,
            offerData: offerData,
            credentialDefinitionDownloader: downloader,
            thid: thid,
            pluto: self.pluto
        )
    }
}
