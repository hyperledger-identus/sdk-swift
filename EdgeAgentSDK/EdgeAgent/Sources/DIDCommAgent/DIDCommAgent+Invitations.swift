import Core
import Domain
import Foundation

public extension DIDCommAgent {
    /// Enumeration representing the type of invitation
    enum InvitationType {
        /// Struct representing a Prism Onboarding invitation
        public struct PrismOnboarding {
            /// Sender of the invitation
            public let from: String
            /// Onboarding endpoint
            public let endpoint: URL
            /// The own DID of the user
            public let ownDID: DID
        }

        /// Case representing a Prism Onboarding invitation
        case onboardingPrism(PrismOnboarding)
        /// Case representing a DIDComm Out-of-Band invitation
        case onboardingDIDComm(OutOfBandInvitation)
        /// Case representing a DIDComm Connectionless Presentation
        case connectionlessPresentation(RequestPresentation)
        /// Case representing a DIDComm Connectionless Issuance
        case connectionlessIssuance(OfferCredential3_0)
    }

    /// Parses the given string as an Out-of-Band invitation
    /// - Parameter url: The string to parse
    /// - Returns: The parsed Out-of-Band invitation
    /// - Throws: `EdgeAgentError` if the string is not a valid URL
    func parseOOBInvitation(url: String) throws -> OutOfBandInvitation {
        if let base64url = Data(base64URLEncoded: url) {
            return try JSONDecoder.didComm().decode(OutOfBandInvitation.self, from: base64url)
        } else if let url = URL(string: url) {
            return try parseOOBInvitation(url: url)
        } else {
            throw CommonError.invalidURLError(url: url)
        }
    }

    /// Parses the given URL as an Out-of-Band invitation
    /// - Parameter url: The URL to parse
    /// - Returns: The parsed Out-of-Band invitation
    /// - Throws: `EdgeAgentError` if the URL is not a valid Out-of-Band invitation
    func parseOOBInvitation(url: URL) throws -> OutOfBandInvitation {
        return try DIDCommInvitationRunner(url: url).run()
    }

    /// Accepts a Prism Onboarding invitation and performs the onboarding process
    /// - Parameter invitation: The Prism Onboarding invitation to accept
    /// - Throws: `EdgeAgentError` if the onboarding process fails
    func acceptPrismInvitation(invitation: InvitationType.PrismOnboarding) async throws {
        struct SendDID: Encodable {
            let did: String
        }
        var request = URLRequest(url: invitation.endpoint)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(SendDID(did: invitation.ownDID.string))
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        do {
            let response = try await URLSession.shared.data(for: request)
            guard let urlResponse = response.1 as? HTTPURLResponse else {
                throw CommonError.invalidCoding(
                    message: "This should not happen cannot convert URLResponse to HTTPURLResponse"
                )
            }
            guard urlResponse.statusCode == 200 else {
                throw CommonError.httpError(
                    code: urlResponse.statusCode,
                    message: String(data: response.0, encoding: .utf8) ?? ""
                )
            }
        }
    }

    /// Parses the given string as an invitation
    /// - Parameter str: The string to parse
    /// - Returns: The parsed invitation
    /// - Throws: `EdgeAgentError` if the invitation is not a valid Prism or OOB type
    func parseInvitation(str: String) async throws -> InvitationType {
        if let prismOnboarding = try? await parsePrismInvitation(str: str) {
            return .onboardingPrism(prismOnboarding)
        } else if let oobMessage = try? parseOOBInvitation(url: str) {
            if let attachment = oobMessage.attachments?.first {
                let invitationType = try await parseAttachmentConnectionlessMessage(oob: oobMessage, attachment: attachment)
                switch invitationType {
                case .connectionlessPresentation(let message):
                    try await pluto.storeMessage(
                        message: message.makeMessage(),
                        direction: .received
                    ).first().await()
                case .connectionlessIssuance(let message):
                    try await pluto.storeMessage(
                        message: message.makeMessage(),
                        direction: .received
                    ).first().await()
                default:
                    break
                }
                return invitationType
            }
            return .onboardingDIDComm(oobMessage)
        }
        throw EdgeAgentError.unknownInvitationTypeError
    }

    /// Parses the given string as a Prism Onboarding invitation
    /// - Parameter str: The string to parse
    /// - Returns: The parsed Prism Onboarding invitation
    /// - Throws: `EdgeAgentError` if the string is not a valid Prism Onboarding invitation
    func parsePrismInvitation(
        str: String
    ) async throws -> InvitationType.PrismOnboarding {
        let prismOnboarding = try PrismOnboardingInvitation(jsonString: str)
        guard
            let url = URL(string: prismOnboarding.body.onboardEndpoint)
        else { throw CommonError.invalidURLError(url: prismOnboarding.body.onboardEndpoint) }

        let ownDID = try await createNewPeerDID(
            services: [.init(
                id: "#didcomm-1",
                type: .one("DIDCommMessaging"),
                serviceEndpoint: .one(.init(
                    uri: "https://localhost:8080/didcomm"
                ))
            )],
            updateMediator: false
        )

        return .init(
            from: prismOnboarding.body.from,
            endpoint: url,
            ownDID: ownDID
        )
    }

    /// Accepts an Out-of-Band (DIDComm) invitation and establishes a new connection
    /// - Parameter invitation: The Out-of-Band invitation to accept
    /// - Throws: `EdgeAgentError` if there is no mediator available or other errors occur during the acceptance process
    func acceptDIDCommInvitation(invitation: OutOfBandInvitation) async throws {
        guard
            let connectionManager
        else { throw EdgeAgentError.noMediatorAvailableError }
        logger.info(message: "Start accept DIDComm invitation")
        let ownDID = try await createNewPeerDID(updateMediator: true)

        logger.info(message: "Sending DIDComm Connection message")

        let pair = try await DIDCommConnectionRunner(
            invitationMessage: invitation,
            pluto: pluto,
            ownDID: ownDID,
            connection: connectionManager
        ).run()
        try await connectionManager.addConnection(pair)
    }

    private func parseAttachmentConnectionlessMessage(
        oob: OutOfBandInvitation,
        attachment: AttachmentDescriptor
    ) async throws -> InvitationType {
        let newDID = try await createNewPeerDID(updateMediator: true)
        switch attachment.data {
        case let value as AttachmentJsonData:
            let normalizeJson = try JSONEncoder.didComm().encode(value.json)
            let message = try JSONDecoder.didComm().decode(Message.self, from: normalizeJson)
            if let request = try? RequestPresentation(fromMessage: message, toDID: newDID) {
                return .connectionlessPresentation(request)
            }
            else if let offer = try? OfferCredential3_0(fromMessage: message, toDID: newDID){
                return .connectionlessIssuance(offer)
            }
            return .onboardingDIDComm(oob)

        case let value as AttachmentBase64:
            let message = try JSONDecoder.didComm().decode(Message.self, from: try value.decoded())
            if let request = try? RequestPresentation(fromMessage: message, toDID: newDID) {
                return .connectionlessPresentation(request)
            }
            else if let offer = try? OfferCredential3_0(fromMessage: message, toDID: newDID){
                return .connectionlessIssuance(offer)
            }
            return .onboardingDIDComm(oob)
        default:
            return .onboardingDIDComm(oob)
        }
    }
}
