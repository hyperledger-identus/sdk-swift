import Domain
import Foundation

extension PolluxImpl {
    public func parseCredential(issuedCredential: Message, options: [CredentialOperationsOptions]) async throws -> Credential {
        guard let issuedAttachment = issuedCredential.attachments.first else {
            throw PolluxError.unsupportedIssuedMessage
        }
        
        switch issuedAttachment.format {
        case "jwt", "", "prism/jwt", .none:
            switch issuedAttachment.data {
            case let json as AttachmentJsonData:
                let jwtString = try JSONEncoder.didComm().encode(json.json).toString()
                guard let credential = try? JWTCredential(jwtString: jwtString) else {
                    return try LegacyJWTCredential(jwtString: jwtString)
                }
                return credential
            case let base64 as AttachmentBase64:
                let jwtString = try base64.decoded().toString()
                guard let credential = try? JWTCredential(jwtString: jwtString) else {
                    return try LegacyJWTCredential(jwtString: jwtString)
                }
                return credential
            default:
                throw PolluxError.unsupportedIssuedMessage
            }
        case "vc+sd-jwt":
            switch issuedAttachment.data {
            case let json as AttachmentJsonData:
                return try SDJWTCredential(sdjwtString: JSONEncoder.didComm().encode(json.json).tryToString())
            case let base64 as AttachmentBase64:
                return try SDJWTCredential(sdjwtString: try base64.decoded().tryToString())
            default:
                throw PolluxError.unsupportedIssuedMessage
            }
        case "anoncreds", "prism/anoncreds", "anoncreds/credential@v1.0":
            guard let thid = issuedCredential.thid else {
                throw PolluxError.messageDoesntProvideEnoughInformation
            }
            guard
                let linkSecretOption = options.first(where: {
                    if case .linkSecret = $0 { return true }
                    return false
                }),
                case let CredentialOperationsOptions.linkSecret(_, secret: linkSecret) = linkSecretOption
            else {
                throw PolluxError.missingAndIsRequiredForOperation(type: "linkSecret")
            }

            guard
                let credDefinitionDownloaderOption = options.first(where: {
                    if case .credentialDefinitionDownloader = $0 { return true }
                    return false
                }),
                case let CredentialOperationsOptions.credentialDefinitionDownloader(definitionDownloader) = credDefinitionDownloaderOption
            else {
                throw PolluxError.missingAndIsRequiredForOperation(type: "credentialDefinitionDownloader")
            }

            guard
                let schemaDownloaderOption = options.first(where: {
                    if case .schemaDownloader = $0 { return true }
                    return false
                }),
                case let CredentialOperationsOptions.schemaDownloader(schemaDownloader) = schemaDownloaderOption
            else {
                throw PolluxError.missingAndIsRequiredForOperation(type: "schemaDownloader")
            }

            switch issuedAttachment.data {
            case let json as AttachmentJsonData:
                return try await ParseAnoncredsCredentialFromMessage.parse(
                    issuerCredentialData: JSONEncoder.didComm().encode(json.json),
                    linkSecret: linkSecret,
                    credentialDefinitionDownloader: definitionDownloader,
                    schemaDownloader: schemaDownloader,
                    thid: thid,
                    pluto: self.pluto
                )
            case let base64 as AttachmentBase64:
                return try await ParseAnoncredsCredentialFromMessage.parse(
                    issuerCredentialData: try base64.decoded(),
                    linkSecret: linkSecret,
                    credentialDefinitionDownloader: definitionDownloader, 
                    schemaDownloader: schemaDownloader,
                    thid: thid,
                    pluto: self.pluto
                )
            default:
                throw PolluxError.unsupportedIssuedMessage
            }
        default:
            throw PolluxError.invalidCredentialError
        }
    }

    public func parseCredential(type: String, credentialPayload: Data, options: [CredentialOperationsOptions]) async throws -> Credential {
        switch type {
        case "jwt", "prism/jwt":
            let jwtString = try credentialPayload.toString()
            guard let credential = try? JWTCredential(jwtString: jwtString) else {
                return try LegacyJWTCredential(jwtString: jwtString)
            }
            return credential
        case "vc+sd-jwt":
            return try SDJWTCredential(sdjwtString: credentialPayload.tryToString())
        case "anoncreds", "prism/anoncreds", "anoncreds/credential@v1.0":
            guard
                let thidOption = options.first(where: {
                    if case .thid = $0 { return true }
                    return false
                }),
                case let CredentialOperationsOptions.thid(thid) = thidOption
            else {
                throw PolluxError.missingAndIsRequiredForOperation(type: "thid")
            }
            guard
                let linkSecretOption = options.first(where: {
                    if case .linkSecret = $0 { return true }
                    return false
                }),
                case let CredentialOperationsOptions.linkSecret(_, secret: linkSecret) = linkSecretOption
            else {
                throw PolluxError.missingAndIsRequiredForOperation(type: "linkSecret")
            }

            guard
                let credDefinitionDownloaderOption = options.first(where: {
                    if case .credentialDefinitionDownloader = $0 { return true }
                    return false
                }),
                case let CredentialOperationsOptions.credentialDefinitionDownloader(definitionDownloader) = credDefinitionDownloaderOption
            else {
                throw PolluxError.missingAndIsRequiredForOperation(type: "credentialDefinitionDownloader")
            }

            guard
                let schemaDownloaderOption = options.first(where: {
                    if case .schemaDownloader = $0 { return true }
                    return false
                }),
                case let CredentialOperationsOptions.schemaDownloader(schemaDownloader) = schemaDownloaderOption
            else {
                throw PolluxError.missingAndIsRequiredForOperation(type: "schemaDownloader")
            }

            return try await ParseAnoncredsCredentialFromMessage.parse(
                issuerCredentialData: credentialPayload,
                linkSecret: linkSecret,
                credentialDefinitionDownloader: definitionDownloader,
                schemaDownloader: schemaDownloader,
                thid: thid,
                pluto: self.pluto
            )
        default:
            throw PolluxError.invalidCredentialError
        }
    }
}
