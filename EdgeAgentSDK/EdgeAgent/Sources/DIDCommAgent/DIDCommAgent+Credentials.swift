import Core
import Combine
import Domain
import Foundation
import Logging
import JSONWebToken

public extension DIDCommAgent {

    /// This function initiates a presentation request for a specific type of credential, specifying the sender's and receiver's DIDs, and any claim filters applicable.
    ///
    /// - Parameters:
    ///   - type: The type of the credential for which the presentation is requested.
    ///   - fromDID: The decentralized identifier (DID) of the entity initiating the request.
    ///   - toDID: The decentralized identifier (DID) of the entity to which the request is being sent.
    ///   - claimFilters: A collection of filters specifying the claims required in the credential.
    /// - Returns: The initiated request for presentation.
    /// - Throws: EdgeAgentError, if there is a problem initiating the presentation request.
    func initiatePresentationRequest(
        type: CredentialType,
        fromDID: DID,
        toDID: DID,
        claimFilters: [ClaimFilter]
    ) throws -> RequestPresentation {
        let rqstStr = try edgeAgent.initiatePresentationRequest(
            type: type,
            fromDID: fromDID,
            toDID: toDID,
            claimFilters: claimFilters
        )
        let attachment: AttachmentDescriptor
        switch type {
        case .jwt:
            let data = try AttachmentBase64(base64: rqstStr.tryToData().base64URLEncoded())
            attachment = AttachmentDescriptor(
                mediaType: "application/json",
                data: data,
                format: "dif/presentation-exchange/definitions@v1.0"
            )
        case .anoncred:
            let data = try AttachmentBase64(base64: rqstStr.tryToData().base64URLEncoded())
            attachment = AttachmentDescriptor(
                mediaType: "application/json",
                data: data,
                format: "anoncreds/proof-request@v1.0"
            )
        }

        return RequestPresentation(
            body: .init(
                proofTypes: [ProofTypes(
                    schema: "",
                    requiredFields: claimFilters.flatMap(\.paths),
                    trustIssuers: nil
                )]
            ),
            attachments: [attachment],
            thid: nil,
            from: fromDID,
            to: toDID
        )
    }

    /// This function verifies the presentation contained within a message.
    ///
    /// - Parameters:
    ///   - message: The message containing the presentation to be verified.
    /// - Returns: A Boolean value indicating whether the presentation is valid (`true`) or not (`false`).
    /// - Throws: EdgeAgentError, if there is a problem verifying the presentation.

    func verifyPresentation(message: Message) async throws -> Bool {
        do {
            let downloader = DownloadDataWithResolver(castor: castor)
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
                throw EdgeAgentError.invalidAttachmentFormat(nil)
            }

            guard let format = attachment.format else {
                throw EdgeAgentError.invalidAttachmentFormat(nil)
            }

            return try await pollux.verifyPresentation(
                type: format,
                presentationPayload: jsonData,
                options: [
                    .presentationRequestId(requestId),
                    .credentialDefinitionDownloader(downloader: downloader),
                    .schemaDownloader(downloader: downloader)
            ])
        } catch {
            logger.error(error: error)
            throw error
        }
    }

    /// This function parses an issued credential message, stores and returns the verifiable credential.
    ///
    /// - Parameters:
    ///   - message: Issue credential Message.
    /// - Returns: The parsed verifiable credential.
    /// - Throws: EdgeAgentError, if there is a problem parsing the credential.
    func processIssuedCredentialMessage(message: IssueCredential3_0) async throws -> Credential {
        guard
            let linkSecret = try await pluto.getLinkSecret().first().await()
        else { throw EdgeAgentError.cannotFindDIDKeyPairIndex }

        let restored = try await self.apollo.restoreKey(linkSecret)
        guard
            let linkSecretString = String(data: restored.raw, encoding: .utf8)
        else { throw EdgeAgentError.cannotFindDIDKeyPairIndex }

        let downloader = DownloadDataWithResolver(castor: castor)
        guard 
            let attachment = message.attachments.first,
            let format = attachment.format
        else {
            throw PolluxError.unsupportedIssuedMessage
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
            throw EdgeAgentError.invalidAttachmentFormat(nil)
        }

        let credential = try await pollux.parseCredential(
            type: format,
            credentialPayload: jsonData,
            options: [
                .linkSecret(id: "", secret: linkSecretString),
                .credentialDefinitionDownloader(downloader: downloader),
                .schemaDownloader(downloader: downloader),
                message.thid.map { .thid($0) } ?? .thid(message.id)
            ]
        )

        guard let storableCredential = credential.storable else {
            return credential
        }
        try await pluto
            .storeCredential(credential: storableCredential)
            .first()
            .await()
        return credential
    }

    /// This function prepares a request credential from an offer given the subject DID.
    ///
    /// - Parameters:
    ///   - did: Subject DID.
    ///   - did: Received offer credential.
    /// - Returns: Created request credential
    /// - Throws: EdgeAgentError, if there is a problem creating the request credential.
    func prepareRequestCredentialWithIssuer(did: DID, offer: OfferCredential3_0) async throws -> RequestCredential3_0? {
        guard did.method == "prism" else { throw PolluxError.invalidPrismDID }
        let didInfo = try await pluto
            .getDIDInfo(did: did)
            .first()
            .await()

        let downloader = DownloadDataWithResolver(castor: castor)
        guard
            let attachment = offer.attachments.first,
            let offerFormat = attachment.format
        else {
            throw PolluxError.unsupportedIssuedMessage
        }

        guard let storedPrivateKey = didInfo?.privateKeys else { throw EdgeAgentError.cannotFindDIDKeyPairIndex }

        let privateKeys = try await storedPrivateKey.asyncMap { try await apollo.restorePrivateKey($0) }
        let exporting = privateKeys.compactMap(\.exporting)

        guard
            let linkSecret = try await pluto.getLinkSecret().first().await()
        else { throw EdgeAgentError.cannotFindDIDKeyPairIndex }

        let restored = try await self.apollo.restoreKey(linkSecret)
        guard
            let linkSecretString = String(data: restored.raw, encoding: .utf8)
        else { throw EdgeAgentError.cannotFindDIDKeyPairIndex }

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
            throw EdgeAgentError.invalidAttachmentFormat(nil)
        }
        let requestString = try await pollux.processCredentialRequest(
            type: offerFormat,
            offerPayload: jsonData,
            options: [
                .exportableKeys(exporting),
                .subjectDID(did),
                .linkSecret(id: did.string, secret: linkSecretString),
                .credentialDefinitionDownloader(downloader: downloader),
                .schemaDownloader(downloader: downloader),
                offer.thid.map { .thid($0) } ?? .thid(offer.id)
            ]
        )

        guard
            let base64String = requestString.data(using: .utf8)?.base64EncodedString()
        else {
            throw CommonError.invalidCoding(message: "Could not encode to base64")
        }
        guard
            let offerPiuri = ProtocolTypes(rawValue: offer.type)
        else {
            throw EdgeAgentError.invalidMessageType(
                type: offer.type,
                shouldBe: [
                    ProtocolTypes.didcommOfferCredential3_0.rawValue
                ]
            )
        }
        let format: String
        switch offerFormat {
        case "prism/jwt":
            format = "prism/jwt"
        case "vc+sd-jwt":
            format = "vc+sd-jwt"
        case "anoncreds/credential-offer@v1.0":
            format = "anoncreds/credential-request@v1.0"
        default:
            throw EdgeAgentError.invalidMessageType(
                type: offerFormat,
                shouldBe: [
                    "prism/jwt",
                    "anoncreds/credential-offer@v1.0"
                ]
            )
        }

        let type = offerPiuri == .didcommOfferCredential ?
            ProtocolTypes.didcommRequestCredential :
            ProtocolTypes.didcommRequestCredential3_0

        let requestCredential = RequestCredential3_0(
            body: .init(
                goalCode: offer.body?.goalCode,
                comment: offer.body?.comment
            ),
            type: type.rawValue,
            attachments: [.init(
                data: AttachmentBase64(base64: base64String),
                format: format
            )],
            thid: offer.thid,
            from: offer.to,
            to: offer.from
        )
        return requestCredential
    }
}
