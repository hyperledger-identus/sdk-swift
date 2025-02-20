import Combine
import Domain
import Foundation
import Pollux
import EdgeAgent
import JSONWebAlgorithms
import JSONWebKey
import JSONWebSignature
import JSONWebToken

final class CredentialListViewModelImpl: CredentialListViewModel {
    @Published var requests = [CredentialListViewState.Requests]()
    @Published var responses = [CredentialListViewState.Responses]()
    @Published var credentials = [CredentialListViewState.Credential]()
    @Published var validCredentials = [CredentialListViewState.Credential]()
    @Published var invalidCredentials = [CredentialListViewState.Credential]()
    @Published var requestId: String? = nil

    private let agent: DIDCommAgent
    private let pluto: Pluto
    private let apollo: Apollo & KeyRestoration

    init(
        agent: DIDCommAgent,
        apollo: Apollo & KeyRestoration,
        pluto: Pluto
    ) {
        self.agent = agent
        self.apollo = apollo
        self.pluto = pluto
        bind()
    }

    private func bind() {
        self.agent.edgeAgent.verifiableCredentials().map {
            $0.map {
                CredentialListViewState.Credential(
                    id: $0.id,
                    issuer: $0.issuer,
                    issuanceDate: $0.storable?.queryCredentialCreated?.formatted() ?? "",
                    type: $0.credentialType
                )
            }
        }
        .replaceError(with: [])
        .receive(on: DispatchQueue.main)
        .assign(to: &$credentials)

        $requestId
            .dropNil()
            .flatMap { self.pluto.getMessage(id: $0) }
            .dropNil()
            .flatMap { message in
                self.agent
                    .edgeAgent
                    .verifiableCredentials()
                    .map {
                        $0.filter { (try? $0.proof?.isValidForPresentation(request: message, options: [])) ?? false}
                    }
            }
            .map {
                $0.map {
                    CredentialListViewState.Credential(
                        id: $0.id,
                        issuer: $0.issuer,
                        issuanceDate: $0.storable?.queryCredentialCreated?.formatted() ?? "",
                        type: $0.credentialType
                    )
                }
            }
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .assign(to: &$validCredentials)

        $requestId
            .dropNil()
            .flatMap { self.pluto.getMessage(id: $0) }
            .dropNil()
            .flatMap { message in
                self.agent
                    .edgeAgent
                    .verifiableCredentials()
                    .map {
                        $0.filter { !((try? $0.proof?.isValidForPresentation(request: message, options: [])) ?? false)}
                    }
            }
            .map {
                $0.map {
                    CredentialListViewState.Credential(
                        id: $0.id,
                        issuer: $0.issuer,
                        issuanceDate: $0.storable?.queryCredentialCreated?.formatted() ?? "",
                        type: $0.credentialType
                    )
                }
            }
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .assign(to: &$invalidCredentials)

        finalThreadFlowResponses()
        finalThreadFlowRequests()

        Task {
            let credentials = try await self.agent.edgeAgent.verifiableCredentials().first().await()
            let linkSecret = try await self.agent.pluto.getLinkSecret().first().await()
            guard credentials.isEmpty, linkSecret != nil else {
                return
            }
            try await buildMockCredentials()
        }
    }

    private func finalThreadFlowRequests() {
        pluto.getAllMessages()
            .map {
                getRequests(messages: $0)
            }
            .replaceError(with: [])
            .assign(to: &$requests)
    }

    private func finalThreadFlowResponses() {
        pluto.getAllMessages()
            .map {
                getResponses(messages: $0)
            }
            .replaceError(with: [])
            .assign(to: &$responses)
    }

    func acceptRequest(id: String, credentialId: String?) {
        Task.detached { [weak self] in
            do {
                guard
                    let self,
                    let message = try await self.pluto.getMessage(id: id).first().await()
                else {
                    return
                }
                switch message.piuri {
                case ProtocolTypes.didcommOfferCredential3_0.rawValue:
                    var authenticationPrivateKey = try apollo.createPrivateKey(parameters: [
                        KeyProperties.type.rawValue: "EC",
                        KeyProperties.curve.rawValue: KnownKeyCurves.ed25519.rawValue
                    ])
                    let newPrismDID = try await self.agent.createNewPrismDID(
                        keys: [(.authentication, authenticationPrivateKey)]
                    )
                    guard let requestCredential = try await self.agent.prepareRequestCredentialWithIssuer(
                        did: newPrismDID,
                        offer: try OfferCredential3_0(fromMessage: message)
                    ) else { throw UnknownError.somethingWentWrongError() }
                    _ = try await self.agent.sendMessage(message: try requestCredential.makeMessage())

                case ProtocolTypes.didcommRequestPresentation.rawValue:
                    let credential = try await self.agent.edgeAgent.verifiableCredentials()
                        .map { $0.compactMap { $0 as? Credential & ProvableCredential} }
                        .map { $0.first { $0.id == credentialId } }
                        .first()
                        .await()
                    guard let credential else {
                        throw UnknownError.somethingWentWrongError()
                    }
                    let presentation = try await self.agent.createPresentationForRequestProof(
                        request: try RequestPresentation(fromMessage: message),
                        credential: credential
                    )
                    _ = try await self.agent.sendMessage(message: try presentation.makeMessage())
                default:
                    throw UnknownError.somethingWentWrongError(customMessage: nil, underlyingErrors: nil)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    func rejectRequest(id: String) {
    }

    private func buildMockCredentials() async throws {
        try await makeDemoCredentialJWT(value: "aliceTest")
        try await makeDemoCredentialJWT(value: "failed")
        try await makeDemoCredentialJWT(value: "testUser@gmail.com")
//        try await makeDemoAnoncredsCredential(value: "")
    }

    private func makeDemoCredentialJWT(value: String) async throws {
        let issuerDID = try await agent.createNewPrismDID()
        let subjectDID = try await agent.createNewPrismDID()
        let payload = MockCredentialClaim(
            iss: issuerDID.string,
            sub: subjectDID.string,
            aud: nil,
            exp: nil,
            nbf: nil,
            iat: nil,
            jti: nil,
            vc: .init(credentialSubject: ["test": value])
        )

        let jwsHeader = DefaultJWSHeaderImpl(algorithm: .ES256K)
        guard
            let key = try await pluto.getDIDPrivateKeys(did: issuerDID).first().await()?.first,
            let jwkD = try await apollo.restorePrivateKey(key).exporting?.jwk
        else {
            return
        }

        ES256KSigner.invertedBytesR_S = true
        let jwt = try JWT.signed(payload: payload, protectedHeader: jwsHeader, key: jwkD.toJoseJWK())
        ES256KSigner.invertedBytesR_S = false

        let credential = try JWTCredential(data: jwt.jwtString.tryToData())
        try await pluto.storeCredential(credential: credential).first().await()
    }

    private func makeDemoAnoncredsCredential(value: String) async throws {
        let mockedIssuer = MockAnoncredsIssuer()
        let offer = try mockedIssuer.createOffer()
        guard let linkSecretStorable = try await pluto.getLinkSecret().first().await() else {
            throw UnknownError.somethingWentWrongError(customMessage: nil, underlyingErrors: nil)
        }
        let linkSecret = try await apollo.restoreKey(linkSecretStorable)

        let credDef = mockedIssuer.credDef
        let defDownloader = MockDownloader(returnData: try credDef.getJson().data(using: .utf8)!)
        let schemaDownloader = MockDownloader(returnData: mockedIssuer.getSchemaJson().data(using: .utf8)!)
        let prover = MockAnoncredsProver(linkSecret: linkSecret, credDef: credDef)
        let request = try prover.createRequest(offer: offer)
        let credentialMetadata = try StorableCredentialRequestMetadata(
            metadataJson: request.1.getJson().tryData(using: .utf8),
            storingId: "1"
        )
        try await pluto.storeCredential(credential: credentialMetadata).first().await()
        let issuedMessage = try mockedIssuer.issueCredential(offer: offer, request: request.0)
        let credential = try await agent.pollux.parseCredential(
            issuedCredential: issuedMessage,
            options: [
                .linkSecret(id: "test", secret: linkSecret.raw.tryToString()),
                .credentialDefinitionDownloader(downloader: defDownloader),
                .schemaDownloader(downloader: schemaDownloader)
            ]
        )

        try await pluto.storeCredential(credential: credential.storable!).first().await()
    }
}

private func getRequests(messages: [Message]) -> [CredentialListViewState.Requests] {
    let groupedByThreadId = Dictionary(grouping: messages) { $0.thid ?? $0.id }
    let sortedValues = groupedByThreadId.mapValues { $0.sorted(by: { $0.createdTime < $1.createdTime }) }
    return sortedValues.compactMap { dicRow -> CredentialListViewState.Requests? in
        guard let last = dicRow.value.last else {
            return nil
        }
        switch last.piuri {
        case "https://didcomm.org/issue-credential/3.0/offer-credential":
            return CredentialListViewState.Requests.proposal(id: last.id, thid: dicRow.key)
        case "https://didcomm.atalaprism.io/present-proof/3.0/request-presentation":
            return CredentialListViewState.Requests.presentationRequest(id: last.id, thid: dicRow.key)
        default:
            return nil
        }
    }
}

private func getResponses(messages: [Message]) -> [CredentialListViewState.Responses] {
    let groupedByThreadId = Dictionary(grouping: messages) { $0.thid ?? $0.id }
    let sortedValues = groupedByThreadId.mapValues { $0.sorted(by: { $0.createdTime < $1.createdTime }) }
    return sortedValues.compactMap { dicRow -> CredentialListViewState.Responses? in
        guard let last = dicRow.value.last else {
            return nil
        }
        switch last.piuri {
        case "https://didcomm.org/issue-credential/3.0/request-credential":
            return CredentialListViewState.Responses.credentialRequest(id: dicRow.key)
        case "https://didcomm.atalaprism.io/present-proof/3.0/presentation":
            return CredentialListViewState.Responses.presentation(id: dicRow.key)
        default:
            return nil
        }
    }
}

private struct MockCredentialClaim: JWTRegisteredFieldsClaims, Codable {
    struct VC: Codable {
        let credentialSubject: [String: String]
    }
    var iss: String?
    var sub: String?
    var aud: [String]?
    var exp: Date?
    var nbf: Date?
    var iat: Date?
    var jti: String?
    var vc: VC
    func validateExtraClaims() throws {
    }
}

private func extractRS(from signature: Data) -> (r: Data, s: Data) {
    let rIndex = signature.startIndex
    let sIndex = signature.index(rIndex, offsetBy: 32)
    let r = signature[rIndex..<sIndex]
    let s = signature[sIndex..<signature.endIndex]
    return (r, s)
}
