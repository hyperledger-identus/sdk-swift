import AnoncredsSwift
import Core
import Domain
import Foundation
import JSONWebAlgorithms
import JSONWebToken
import JSONWebSignature
import Sextant
import JSONSchema

extension PolluxImpl {

    private enum ValidJsonTypeFilter: String {
        case string
        case number
        case boolean
    }

    public func verifyPresentation(message: Message, options: [CredentialOperationsOptions]) async throws -> Bool {
        guard 
            let attachment = message.attachments.first,
            let requestId = message.thid
        else {
            throw PolluxError.couldNotFindPresentationInAttachments
        }

        let jsonData: Data
        switch attachment.data {
        case let attchedData as AttachmentBase64:
            guard let decoded = Data(fromBase64URL: attchedData.base64) else {
                throw CommonError.invalidCoding(message: "Invalid base64 url attachment")
            }
            jsonData = decoded
        case let attchedData as AttachmentJsonData:
            jsonData = try JSONEncoder.didComm().encode(attchedData.json)
        default:
            throw PolluxError.invalidAttachmentType(supportedTypes: ["Json", "Base64"])
        }

        switch attachment.format {
        case "dif/presentation-exchange/submission@v1.0":
            let request = try await getDefinition(id: requestId)
            return try await VerifyPresentationSubmission(
                castor: castor,
                parsers: presentationExchangeParsers
            )
            .verifyPresentationSubmission(
                json: jsonData,
                presentationRequest: request
            )
        case "anoncreds/proof@v1.0":
            return try await verifyAnoncreds(
                presentation: jsonData,
                requestId: requestId,
                options: options
            )
        default:
            throw PolluxError.unsupportedAttachmentFormat(attachment.format)
        }
    }

    public func verifyPresentation(
        type: String,
        presentationPayload: Data,
        options: [CredentialOperationsOptions]
    ) async throws -> Bool {
        guard
            let requestIdOption = options.first(where: {
                if case .presentationRequestId = $0 { return true }
                return false
            }),
            case let CredentialOperationsOptions.presentationRequestId(requestId) = requestIdOption
        else {
            throw PolluxError.invalidPrismDID
        }

        switch type {
        case "dif/presentation-exchange/submission@v1.0":
            return try await verifyPresentationSubmission(json: presentationPayload, requestId: requestId)
        case "anoncreds/proof@v1.0":
            return try await verifyAnoncreds(
                presentation: presentationPayload,
                requestId: requestId,
                options: options
            )
        default:
            throw PolluxError.unsupportedAttachmentFormat(type)
        }
    }

    private func getDefinition(id: String) async throws -> PresentationExchangeRequest {
        guard
            let request = try await pluto.getMessage(id: id).first().await(),
            let attachmentData = request.attachments.first?.data
        else {
            throw PolluxError.couldNotFindPresentationRequest(id: id)
        }

        let json: Data
        switch attachmentData {
        case let jsonData as AttachmentJsonData:
            json = try JSONEncoder.didComm().encode(jsonData.json)
        case let base64Data as AttachmentBase64:
            json = try base64Data.decoded()
        default:
            throw PolluxError.invalidAttachmentType(supportedTypes: ["base64", "json"])
        }

        return try JSONDecoder.didComm().decode(PresentationExchangeRequest.self, from: json)
    }

    private func verifyPresentationSubmission(json: Data, requestId: String) async throws -> Bool {
        let presentationContainer = try JSONDecoder.didComm().decode(PresentationContainer.self, from: json)
        let presentationRequest = try await getDefinition(id: requestId)
        guard let submission = presentationContainer.presentationSubmission else {
            throw PolluxError.presentationSubmissionNotAvailable
        }

        return try await VerifyPresentationSubmission(
            castor: castor,
            parsers: presentationExchangeParsers
        ).verifyPresentationSubmission(
            json: json,
            presentationRequest: presentationRequest
        )
    }

    private func verifyAnoncreds(
        presentation: Data,
        requestId: String,
        options: [CredentialOperationsOptions]
    ) async throws -> Bool {
        let anonPresentation = try AnoncredsSwift.Presentation(jsonString: presentation.tryToString())
        let requestPresentation = try await getAnoncredsRequest(id: requestId)

        let internalPresentation = try JSONDecoder.didComm().decode(AnonPresentation.self, from: presentation)
        let schemaIds = internalPresentation.identifiers.map(\.schemaId)
        let credentialDefinitionsIds = internalPresentation.identifiers.map(\.credDefId)
        let anonSchemas = try await getSchemas(ids: schemaIds, options: options)
            .mapValues { try JSONDecoder.didComm().decode(AnonCredentialSchema.self, from: $0) }
            .mapValues {
                Schema(
                    name: $0.name,
                    version: $0.version,
                    attrNames: $0.attrNames.map { AttributeNames($0) } ?? AttributeNames(),
                    issuerId: $0.issuerId
                )
            }
        let anonCredentialDefinitions = try await getCredentialDefinitions(
            ids: credentialDefinitionsIds,
            options: options
        ).mapValues { try AnoncredsSwift.CredentialDefinition(jsonString: $0.tryToString()) }

        return try Verifier().verifyPresentation(
            presentation: anonPresentation,
            presentationRequest: requestPresentation,
            schemas: anonSchemas,
            credentialDefinitions: anonCredentialDefinitions
        )
    }

    private func getAnoncredsRequest(id: String) async throws -> AnoncredsSwift.PresentationRequest {
        guard
            let request = try await pluto.getMessage(id: id).first().await(),
            let attachmentData = request.attachments.first?.data
        else {
            throw PolluxError.couldNotFindPresentationRequest(id: id)
        }

        let json: Data
        switch attachmentData {
        case let jsonData as AttachmentJsonData:
            json = try JSONEncoder.didComm().encode(jsonData.json)
        case let base64Data as AttachmentBase64:
            guard let data = try Data(fromBase64URL: base64Data.base64.tryToData()) else {
                throw CommonError.invalidCoding(message: "Could not decode base64 message attchment")
            }
            json = data
        default:
            throw PolluxError.invalidAttachmentType(supportedTypes: [])
        }

        return try PresentationRequest(jsonString: json.tryToString())
    }

    private func getSchemas(ids: [String], options: [CredentialOperationsOptions]) async throws -> [String: Data] {
        if
            let schemasOption = options.first(where: {
                if case .schema = $0 { return true }
                return false
            }),
            case let CredentialOperationsOptions.schema(id, json) = schemasOption
        {
            return try [id: json.tryToData()]
        }

        guard
            let schemaDownloaderOption = options.first(where: {
                if case .schemaDownloader = $0 { return true }
                return false
            }),
            case let CredentialOperationsOptions.schemaDownloader(downloader) = schemaDownloaderOption
        else {
            throw PolluxError.missingAndIsRequiredForOperation(type: "schemaDownloader")
        }
        let schemas = try await ids.asyncMap { ($0, try await downloader.downloadFromEndpoint(urlOrDID: $0)) }
        return schemas.reduce( [String: Data]()) { partialResult, schemas in
            var dic = partialResult
            dic[schemas.0] = schemas.1
            return dic
        }
    }

    private func getCredentialDefinitions(
        ids: [String],
        options: [CredentialOperationsOptions]
    ) async throws -> [String: Data] {
        if
            let credentialDefinitionsOption = options.first(where: {
                if case .credentialDefinition = $0 { return true }
                return false
            }),
            case let CredentialOperationsOptions.credentialDefinition(id, json) = credentialDefinitionsOption
        {
            return try [id: json.tryToData()]
        }

        guard
            let credentialDefinitionsDownloaderOption = options.first(where: {
                if case .credentialDefinitionDownloader = $0 { return true }
                return false
            }),
            case let CredentialOperationsOptions.credentialDefinitionDownloader(downloader) = credentialDefinitionsDownloaderOption
        else {
            throw PolluxError.missingAndIsRequiredForOperation(type: "credentialDefinitionDownloader")
        }
        let definitions = try await ids.asyncMap { ($0, try await downloader.downloadFromEndpoint(urlOrDID: $0)) }
        return definitions.reduce( [String: Data]()) { partialResult, definitions in
            var dic = partialResult
            dic[definitions.0] = definitions.1
            return dic
        }
    }
}

private struct AnonPresentation: Codable {
    struct Identifiers: Codable {
        let schemaId: String
        let credDefId: String
    }

    let identifiers: [Identifiers]
}

private struct ValidateJsonSchemaContainer: Codable {
    let value: AnyCodable
}
