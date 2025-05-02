import Combine
import Domain
import Foundation
import Pollux
import EdgeAgent

class PresentationDetailViewModelImpl: PresentationDetailViewModel {
    @Published var presentation = PresentationDetailViewState.Presentation(
        id: "",
        name: "",
        to: "",
        claims: []
    )

    @Published var receivedPresentations: [PresentationDetailViewState.ReceivedPresentation] = []
    @Published var isVerified = false

    private let agent: DIDCommAgent
    private let pluto: Pluto

    init(
        id: String,
        agent: DIDCommAgent,
        pluto: Pluto
    ) {
        self.agent = agent
        self.pluto = pluto
        bind(messageId: id)
    }

    func bind(messageId: String) {
        let emptyPresentation = PresentationDetailViewState.Presentation(
            id: "",
            name: "",
            to: "",
            claims: []
        )

        pluto
            .getMessage(id: messageId)
            .first()
            .tryMap {
                guard let message = $0 else { return nil }
                let presentationRequest = try RequestPresentation(fromMessage: message)
                guard let attachment = presentationRequest.attachments.first else {
                    return nil
                }
                let requestData = try getDataFromAttachment(attachmentDescriptor: attachment)

                let request = try JSONDecoder.didComm().decode(PresentationExchangeRequest.self, from: requestData)
                let claims = request.presentationDefinition.inputDescriptors.flatMap(\.constraints.fields).compactMap {
                    PresentationDetailViewState.Claim(name: $0.name ?? "Claim", type: $0.filter?.type ?? "", value: $0.path.first ?? "")
                }
                return PresentationDetailViewState.Presentation(
                    id: messageId,
                    name: "",
                    to: message.to?.string ?? "",
                    claims: claims
                )
            }
            .replaceNil(with:emptyPresentation)
            .replaceError(with: emptyPresentation)
            .assign(to: &$presentation)

        pluto
            .getMessage(id: messageId)
            .first { $0 != nil }
            .flatMap {
                self.getPresentations(requestMessage: $0!)
            }
            .map { $0.sorted { $0.createdTime < $1.createdTime }}
            .flatMap { presentations in
                Future {
                    await presentations.asyncMap {
                        do {
                            let verified = try await self.agent.verifyPresentation(message: $0)
                            return PresentationDetailViewState.ReceivedPresentation(
                                id: $0.id,
                                isVerified: verified,
                                error: []
                            )
                        } catch {
                            switch error {
                            case let localizable as KnownPrismError:
                                return PresentationDetailViewState.ReceivedPresentation(
                                    id: $0.id,
                                    isVerified: false,
                                    error: [localizable.errorDescription!]
                                )
                            default:
                                return PresentationDetailViewState.ReceivedPresentation(
                                    id: $0.id,
                                    isVerified: false,
                                    error: [error.localizedDescription]
                                )
                            }

                        }
                    }
                }
            }
            .replaceError(with: [])
            .assign(to: &$receivedPresentations)

        $receivedPresentations.map{
            $0.contains(where: \.isVerified)
        }.assign(to: &$isVerified)
    }

//    private func receivedPresentations(message: [Message]) -> AnyPublisher<[PresentationDetailViewState.ReceivedPresentation], Error> {
//        message
//            .publisher
//            .flatMap {
//                self.receivedPresentation(message: $0)
//            }
//            .collect()
//            .eraseToAnyPublisher()
//    }
//
//    private func receivedPresentation(message: Message) -> AnyPublisher<PresentationDetailViewState.ReceivedPresentation, Error> {
//        Future { [weak self] in
//            guard let self else { return PresentationDetailViewState.ReceivedPresentation(id: "0", credentialCount: 0, isVerified: false, errors: []) }
//            do {
//                let verification = try await self.agent.verifyPresentation(message: message)
//                return .init(
//                    credentialCount: 0,
//                    isVerified: verification,
//                    error: nil
//                )
//            } catch {
//                return .init(
//                    id: message.id,
//                    credentialCount: 0,
//                    isVerified: false,
//                    error: [error.localizedDescription]
//                )
//            }
//        }
//        .eraseToAnyPublisher()
//    }

    private func getPresentations(requestMessage: Message) -> AnyPublisher<[Message], Error> {
        pluto
            .getAllMessagesReceived()
            .map {
                $0.filter {
                    $0.thid != nil && ($0.thid == requestMessage.thid || $0.thid == requestMessage.id)
                }
            }
            .eraseToAnyPublisher()
    }
}

public func getDataFromAttachment(attachmentDescriptor: AttachmentDescriptor) throws -> Data {
    switch attachmentDescriptor.data {
    case let value as AttachmentBase64:
        return Data(base64Encoded: value.base64)!
    case let value as AttachmentJsonData:
        return try JSONEncoder().encode(value.json) 
    default:
        throw UnknownError.somethingWentWrongError(customMessage: nil, underlyingErrors: nil)
    }
}
