import Combine
import Domain
import Foundation
import EdgeAgent

final class MessageDetailViewModelImpl: MessageDetailViewModel {
    @Published var state = MessageDetailViewState(
        common: .init(
            id: "",
            type: "",
            title: "",
            from: "",
            to: "",
            bodyString: "",
            thid: "",
            didRespond: false
        ),
        specific: .finishedThreads
    )

    @Published var messagesThread = [MessageDetailViewState.Message]()
    @Published var error: FancyToast?
    @Published var loading = false
    @Published var dismiss = false

    private let messageId: String
    private let pluto: Pluto
    private let agent: DIDCommAgent
    private var message: Message?
    private var cancellables = Set<AnyCancellable>()

    init(messageId: String, pluto: Pluto, agent: DIDCommAgent) {
        self.messageId = messageId
        self.pluto = pluto
        self.agent = agent

        bind()
    }

    func bind() {
        pluto
            .getMessage(id: messageId)
            .map { [weak self] in
                $0.map {
                    self?.message = $0
                    return MessageDetailViewState(
                        common: .init(
                            id: $0.id,
                            type: $0.piuri,
                            title: getMessageTitle(messageType: $0.piuri),
                            from: $0.from?.string,
                            to: $0.to?.string,
                            bodyString: nil,
                            thid: $0.thid,
                            didRespond: false
                        ),
                        specific: getSpecificByType(msg: $0)
                    )
                }
            }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let state = $0 else { return }
                self?.state = state
            }
            .store(in: &cancellables)
    }

    func accept() {
        guard
            let message,
            message.direction == .received,
            let msgType = ProtocolTypes(rawValue: message.piuri)
        else { return }
        let agent = self.agent
        Task.detached { [weak self] in
            do {
                switch msgType {
                case .didcommPresentation:
                    let presentation = try Presentation(fromMessage: message)
                case .didcommRequestPresentation:
                    let credential = try await agent.edgeAgent.verifiableCredentials().map { $0.first }.first().await()
                    guard let credential else {
                        throw UnknownError.somethingWentWrongError()
                    }
                    let presentation = try await agent.createPresentationForRequestProof(
                        request: try RequestPresentation(fromMessage: message),
                        credential: credential
                    )
                    _ = try await agent.sendMessage(message: try presentation.makeMessage())
                case .didcommOfferCredential, .didcommOfferCredential3_0:
                    let newPrismDID = try await agent.createNewPrismDID()
                    guard let requestCredential = try await agent.prepareRequestCredentialWithIssuer(
                        did: newPrismDID,
                        offer: try OfferCredential3_0(fromMessage: message)
                    ) else { throw UnknownError.somethingWentWrongError() }
                    _ = try await agent.sendMessage(message: try requestCredential.makeMessage())
                case .didcommconnectionRequest:
                    let request = try ConnectionRequest(fromMessage: message)
                    let accept = ConnectionAccept(fromRequest: request)
                    _ = try await agent.sendMessage(message: try accept.makeMessage())
                default:
                    break
                }
            } catch let error as LocalizedError {
                await MainActor.run { [weak self] in
                    self?.error = FancyToast(
                        type: .error,
                        title: error.localizedDescription,
                        message: error.errorDescription ?? ""
                    )
                }

            } catch {
                await MainActor.run { [weak self] in
                    self?.error = FancyToast(
                        type: .error,
                        title: error.localizedDescription,
                        message: ""
                    )
                }
            }
        }
    }

    func refuse() {
    }
}

private func getSpecificByType(msg: Message) -> MessageDetailViewState.SpecificDetail {
    guard
        msg.direction == .received,
        let msgType = ProtocolTypes(rawValue: msg.piuri)
    else {
        return .finishedThreads
    }
    switch msgType {
    case .didcommRequestPresentation:
        return .acceptRefuse
    case .didcommIssueCredential, .didcommIssueCredential3_0:
        return .finishedThreads
    case .didcommOfferCredential:
        do {
            let (domain, challenge) = try getDomainAndChallenge(msg: msg)
            return .credentialDomainChallenge(domain: domain ?? "", challenge: challenge ?? "")
        } catch {
            return .acceptRefuse
        }
    case .didcommOfferCredential3_0:
        return .acceptRefuse
    case .didcommProposeCredential, .didcommProposeCredential3_0:
        return .acceptRefuse
    case .didcommRequestCredential, .didcommRequestCredential3_0:
        return .acceptRefuse
    case .didcommconnectionRequest:
        return .acceptRefuse
    default:
        return .finishedThreads
    }
}

private func getDomainAndChallenge(msg: Message) throws -> (domain: String?, challenge: String?) {
    guard let offerData = msg
        .attachments
        .map({
            switch $0.data {
            case let json as AttachmentJsonData:
                return json.json
            default:
                return nil
            }
        })
        .compactMap({ $0 })
        .first
    else { throw PolluxError.offerDoesntProvideEnoughInformation }
    let jsonObject = try JSONSerialization.jsonObject(with: JSONEncoder().encode(offerData))
    return (findValue(forKey: "domain", in: jsonObject), findValue(forKey: "challenge", in: jsonObject))
}

private func findValue(forKey key: String, in json: Any) -> String? {
    if let dict = json as? [String: Any] {
        if let value = dict[key] {
            return value as? String
        }
        for (_, subJson) in dict {
            if let foundValue = findValue(forKey: key, in: subJson) {
                return foundValue
            }
        }
    } else if let array = json as? [Any] {
        for subJson in array {
            if let foundValue = findValue(forKey: key, in: subJson) {
                return foundValue
            }
        }
    }
    return nil
}

private func getMessageTitle(messageType: String) -> String {
    guard let msgType = ProtocolTypes(rawValue: messageType) else {
        return messageType
    }
    return getTitle(for: msgType)
}

private func getTitle(for protocolType: ProtocolTypes) -> String {
    switch protocolType {
    case .didcommBasicMessage:
        return "Basic Message"
    case .didcommMediationRequest:
        return "Mediation Request"
    case .didcommMediationGrant:
        return "Mediation Grant"
    case .didcommMediationDeny:
        return "Mediation Deny"
    case .didcommMediationKeysUpdate:
        return "Mediation Keys Update"
    case .didcommPresentation:
        return "Presentation"
    case .didcommRequestPresentation:
        return "Request Presentation"
    case .didcommProposePresentation:
        return "Propose Presentation"
    case .didcommCredentialPreview:
        return "Credential Preview"
    case .didcommIssueCredential:
        return "Issue Credential"
    case .didcommIssueCredential3_0:
        return "Issue Credential 3.0"
    case .didcommOfferCredential:
        return "Offer Credential"
    case .didcommOfferCredential3_0:
        return "Offer Credential 3.0"
    case .didcommProposeCredential:
        return "Propose Credential"
    case .didcommProposeCredential3_0:
        return "Propose Credential 3.0"
    case .didcommRequestCredential:
        return "Request Credential"
    case .didcommRequestCredential3_0:
        return "Request Credential 3.0"
    case .didcommconnectionRequest:
        return "Connection Request"
    case .didcommconnectionResponse:
        return "Connection Response"
    case .didcomminvitation:
        return "Invitation"
    case .prismOnboarding:
        return "Prism Onboarding"
    case .pickupRequest:
        return "Pickup Request"
    case .pickupDelivery:
        return "Pickup Delivery"
    case .pickupStatus:
        return "Pickup Status"
    case .pickupReceived:
        return "Pickup Received"
    case .didcommCredentialPreview3_0:
        return "Credential Preview"
    case .didcommRevocationNotification:
        return "Revocation Notification"
    case .didcommReportProblem:
        return "Problem Reporting"
    }
}
