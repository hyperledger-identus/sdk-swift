import Domain
import Foundation

extension PolluxImpl: CredentialImporter {
    public func importCredential(credentialData: Data, restorationType: String, options: [CredentialOperationsOptions]) async throws -> Credential {
        switch restorationType {
        case "anoncred":
            guard
                let credDefinitionDownloaderOption = options.first(where: {
                    if case .credentialDefinitionDownloader = $0 { return true }
                    return false
                }),
                case let CredentialOperationsOptions.credentialDefinitionDownloader(defDownloader) = credDefinitionDownloaderOption
            else {
                throw PolluxError.invalidPrismDID
            }
            guard
                let credSchemaDownloaderOption = options.first(where: {
                    if case .schemaDownloader = $0 { return true }
                    return false
                }),
                case let CredentialOperationsOptions.schemaDownloader(schemaDownloader) = credSchemaDownloaderOption
            else {
                throw PolluxError.invalidPrismDID
            }
            return try await importAnoncredCredential(
                credentialData: credentialData,
                credentialDefinitionDownloader: defDownloader,
                schemaDownloader: schemaDownloader
            )
        case "jwt":
            guard let credential = try? JWTCredential(jwtString: credentialData.toString()) else {
                return try LegacyJWTCredential(data: credentialData)
            }
            return credential
        case "sd-jwt":
            return try SDJWTCredential(sdjwtString: credentialData.tryToString())
        default:
            throw PolluxError.invalidCredentialError
        }
    }
}

private func importAnoncredCredential(
    credentialData: Data,
    credentialDefinitionDownloader: Downloader,
    schemaDownloader: Downloader
) async throws -> Credential {
    let domainCred = try JSONDecoder().decode(AnonCredential.self, from: credentialData)
    let credentialDefinitionData = try? await credentialDefinitionDownloader
        .downloadFromEndpoint(urlOrDID: domainCred.credentialDefinitionId)
    let cdData = try credentialDefinitionData.map { try JSONDecoder.didComm().decode(AnonCredentialDefinition.self, from: $0) }
    let schemaData = (try? await schemaDownloader
        .downloadFromEndpoint(urlOrDID: domainCred.schemaId))
        .flatMap { try? JSONDecoder.didComm().decode(AnonCredentialSchema.self, from: $0) }

    return AnoncredsCredentialStack(
        schema: schemaData,
        definition: cdData,
        credential: domainCred
    )
}
