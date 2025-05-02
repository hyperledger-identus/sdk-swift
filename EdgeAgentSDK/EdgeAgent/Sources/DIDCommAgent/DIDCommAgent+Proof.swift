import Core
import Combine
import Domain
import Foundation
import Logging
import JSONWebToken

public extension DIDCommAgent {
    
    /// This function creates a Presentation from a request verfication.
    ///
    /// - Parameters:
    ///   - request: Request message received.
    ///   - credential: Verifiable Credential to present.
    /// - Returns: Presentation message prepared to send.
    /// - Throws: EdgeAgentError, if there is a problem creating the presentation.
    func createPresentationForRequestProof(
        request: RequestPresentation,
        credential: Credential,
        options: [CredentialOperationsOptions] = []
    ) async throws -> Presentation {
        guard let proofableCredential = credential.proof else {
            throw EdgeAgentError.credentialCannotIssuePresentations
        }

        guard let requestType = request.attachments.first?.format else {
            throw EdgeAgentError.invalidAttachmentFormat(nil)
        }
        let presentationString: String
        let format: String
        switch requestType {
        case "anoncreds/proof-request@v1.0":
            guard
                let linkSecret = try await pluto.getLinkSecret().first().await()
            else { throw EdgeAgentError.cannotFindDIDKeyPairIndex }

            let restored = try await self.apollo.restoreKey(linkSecret)
            guard
                let linkSecretString = String(data: restored.raw, encoding: .utf8)
            else { throw EdgeAgentError.cannotFindDIDKeyPairIndex }
            format = "anoncreds/proof@v1.0"
            presentationString = try proofableCredential.presentation(
                request: request.makeMessage(),
                options: options + [
                    .linkSecret(id: "", secret: linkSecretString)
                ]
            )
        case "prism/jwt", "vc+sd-jwt", "dif/presentation-exchange/definitions@v1.0":
            guard
                let subjectDIDString = credential.subject
            else {
                throw PolluxError.invalidPrismDID
            }

            let subjectDID = try DID(string: subjectDIDString)

            guard
                let storedPrivateKeys = try await pluto.getDIDPrivateKeys(did: subjectDID).first().await()
            else { throw EdgeAgentError.cannotFindDIDKeyPairIndex }

            let privateKeys = try await storedPrivateKeys.asyncMap { try await apollo.restorePrivateKey($0) }
            let exporting = privateKeys.compactMap(\.exporting)

            format = requestType == "prism/jwt" ? "prism/jwt" : "dif/presentation-exchange/submission@v1.0"

            presentationString = try proofableCredential.presentation(
                request: request.makeMessage(),
                options: options + [
                    .exportableKeys(exporting),
                    .subjectDID(subjectDID)
                ]
            )
        default:
            throw EdgeAgentError.invalidAttachmentFormat(requestType)
        }

        SDKLogger(category: .edgeAgent).info(message: "Presentation: \(presentationString)")

        let base64String = try presentationString.tryToData().base64URLEncoded()

        return Presentation(
            body: .init(
                goalCode: request.body.goalCode,
                comment: request.body.comment
            ),
            attachments: [.init(
                data: AttachmentBase64(base64: base64String),
                format: format
            )],
            thid: request.thid ?? request.id,
            from: request.to,
            to: request.from
        )
    }
}
