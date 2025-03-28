import Core
import Combine
import Domain
import Foundation
import Logging
import JSONWebToken

// MARK: Verifiable credentials functionalities
public extension EdgeAgent {
    /// This function returns the verifiable credentials stored in pluto database
    ///
    /// - Returns:  A publisher that emits an array of `VerifiableCredential` and completes when all the
    ///              credentials are emitted or terminates with an error if any occurs
    func verifiableCredentials() -> AnyPublisher<[Credential], Error> {
        let pollux = self.pollux
        return pluto.getAllCredentials().tryMap {
            $0.compactMap {
                try? pollux.restoreCredential(
                    restorationIdentifier: $0.recoveryId,
                    credentialData: $0.credentialData
                )
            }
        }
        .eraseToAnyPublisher()
    }

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
    ) throws -> String {
        let request = try self.pollux.createPresentationRequest(
            type: type,
            toDID: toDID,
            name: UUID().uuidString,
            version: "1.0",
            claimFilters: claimFilters
        )

        let rqstStr = try request.tryToString()
        logger.debug(message: "Request: \(rqstStr)")
        return rqstStr
    }

    /// This function verifies the presentation contained within a message.
    ///
    /// - Parameters:
    ///   - message: The message containing the presentation to be verified.
    /// - Returns: A Boolean value indicating whether the presentation is valid (`true`) or not (`false`).
    /// - Throws: EdgeAgentError, if there is a problem verifying the presentation.

    func verifyPresentation(
        type: String,
        presentationPayload: Data,
        requestId: String
    ) async throws -> Bool {
        do {
            let downloader = DownloadDataWithResolver(castor: castor)
            return try await pollux.verifyPresentation(
                type: type,
                presentationPayload: presentationPayload,
                options: [
                    .presentationRequestId(requestId),
                    .credentialDefinitionDownloader(downloader: downloader),
                    .schemaDownloader(downloader: downloader)
                ]
            )
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
    func processIssuedCredential(type: String, issuedCredentialPayload: Data) async throws -> Credential {
        guard
            let linkSecret = try await pluto.getLinkSecret().first().await()
        else { throw EdgeAgentError.cannotFindDIDKeyPairIndex }

        let restored = try await self.apollo.restoreKey(linkSecret)
        guard
            let linkSecretString = String(data: restored.raw, encoding: .utf8)
        else { throw EdgeAgentError.cannotFindDIDKeyPairIndex }

        let downloader = DownloadDataWithResolver(castor: castor)
        let credential = try await pollux.parseCredential(
            type: type,
            credentialPayload: issuedCredentialPayload,
            options: [
                .linkSecret(id: "", secret: linkSecretString),
                .credentialDefinitionDownloader(downloader: downloader),
                .schemaDownloader(downloader: downloader)
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
    func prepareRequestCredentialWithIssuer(
        did: DID,
        type: String,
        offerPayload: Data
    ) async throws -> String {
        guard did.method == "prism" else { throw PolluxError.invalidPrismDID }
        let didInfo = try await pluto
            .getDIDInfo(did: did)
            .first()
            .await()

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

        let downloader = DownloadDataWithResolver(castor: castor)
        return try await pollux.processCredentialRequest(
            type: type,
            offerPayload: offerPayload,
            options: [
                .exportableKeys(exporting),
                .subjectDID(did),
                .linkSecret(id: did.string, secret: linkSecretString),
                .credentialDefinitionDownloader(downloader: downloader),
                .schemaDownloader(downloader: downloader)
            ]
        )
    }
}
