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
                return try await processJWTCredentialRequest(
                    offerData: try JSONEncoder.didComm().encode(json.json),
                    options: options
                )
            default:
                throw PolluxError.offerDoesntProvideEnoughInformation
            }
        case "vc+sd-jwt":
            switch offerAttachment.data {
            case let json as AttachmentJsonData:
                return try await processSDJWTCredentialRequest(
                    offerData: try JSONEncoder.didComm().encode(json.json),
                    options: options
                )
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
                    offerData: try JSONEncoder.didComm().encode(attachmentData.json),
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

    public func processCredentialRequest(
        type: String,
        offerPayload: Data,
        options: [CredentialOperationsOptions]
    ) async throws -> String {
        switch type {
        case "jwt", "prism/jwt":
            return try await processJWTCredentialRequest(offerData: offerPayload, options: options)
        case "vc+sd-jwt":
            return try await processSDJWTCredentialRequest(offerData: offerPayload, options: options)
        case "anoncreds/credential-offer@v1.0":
            guard
                let thidOption = options.first(where: {
                    if case .thid = $0 { return true }
                    return false
                }),
                case let CredentialOperationsOptions.thid(thid) = thidOption
            else {
                throw PolluxError.missingAndIsRequiredForOperation(type: "thid")
            }
            return try await processAnoncredsCredentialRequest(
                offerData: offerPayload,
                thid: thid,
                options: options
            )
        default:
            break
        }
        throw PolluxError.invalidCredentialError
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
                if case .exportableKeys = $0 { return true }
                return false
            }),
            case let CredentialOperationsOptions.exportableKeys(exportableKeys) = exportableKeyOption,
            let exportableFirstKey = exportableKeys.filter({
                $0.jwk.crv?.lowercased() == "secp256k1"
                && !($0.jwk.kid?.contains("#master") ?? true) // TODO: This is a hardcoded fix, since prism DID doesnt not recognize master key
            }).first
        else {
            throw PolluxError.requiresExportableKeyForOperation(operation: "Create Credential Request")
        }

        return try await CreateJWTCredentialRequest.create(didStr: did.string, key: exportableFirstKey, offerData: offerData)
    }

    private func processSDJWTCredentialRequest(offerData: Data, options: [CredentialOperationsOptions]) async throws -> String {
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
                if case .exportableKeys = $0 { return true }
                return false
            }),
            case let CredentialOperationsOptions.exportableKeys(exportableKeys) = exportableKeyOption
        else {
            throw PolluxError.requiresExportableKeyForOperation(operation: "Create Credential Request")
        }

        return try await CreateSDJWTCredentialRequest.create(didStr: did.string, keys: exportableKeys, offerData: offerData)
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
