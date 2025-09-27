import Core
import Domain
import Foundation

public struct AuthenticateChallenger {
    let castor: Castor
    let apollo: Apollo
    let scheme: AuthenticateDeepLink
    let deepLinkPusher: DeepLinkPusher

    public init(
        castor: Castor,
        apollo: Apollo,
        scheme: AuthenticateDeepLink,
        deepLinkPusher: DeepLinkPusher
    ) {
        self.castor = castor
        self.apollo = apollo
        self.scheme = scheme
        self.deepLinkPusher = deepLinkPusher
    }

    public func createPrismDIDForAuthenticate(publicKey: PublicKey) throws -> DID {
        try castor.createPrismDID(
            masterPublicKey: publicKey,
            services: [.init(
                id: "deeplink",
                type: .one("deeplink"),
                serviceEndpoint: .one(.init(uri: scheme.scheme + "://" + scheme.host))
            )]
        )
    }

    public func processChallengeForAuthenticate(
        did: DID,
        challengerName: String,
        challengerPublicKey: PublicKey,
        challenge: String
    ) throws -> ChallengeObject {
        let challengerDID = try createPrismDIDForAuthenticate(publicKey: challengerPublicKey)

        return .init(
            challengedDID: did.string,
            challenge: challenge,
            challengerName: challengerName,
            challengerDID: challengerDID.string
        )
    }

    public func startAuthenticateWithPrism(
        challengeObject: ChallengeObject
    ) async throws {
        let did = try castor.parseDID(str: challengeObject.challengedDID)
        let didDocument = try await castor.resolveDID(did: did)

        guard let service = didDocument.services
            .first(where: { $0.type.array.contains(where: { $0 == "deeplink" }) })?
            .serviceEndpoint.array.first?.uri
        else { throw AuthenticateError.cannotFindDeepLinkServiceError }

        guard
            var components = URLComponents(string: service)
        else { throw AuthenticateError.invalidDeepLinkError }

        components.queryItems = challengeObject.queryItems

        guard
            let url = components.url
        else { throw AuthenticateError.invalidDeepLinkError }

        guard try await deepLinkPusher.openDeepLink(url: url) else {
            throw AuthenticateError.deepLinkNotAvailableError
        }
    }

    public func submitedPrismChallenge(url: URL) throws -> SubmitedChallengeObject {
        guard
            url.scheme == scheme.scheme,
            url.host == scheme.host,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        else { throw AuthenticateError.urlNotAuthenticateServiceError }

        return try SubmitedChallengeObject(fromQueryItems: components.queryItems ?? [])
    }

    public func verifyChallenge(
        submitedChallengeResponse: SubmitedChallengeObject
    ) async throws -> Bool {
        guard
            let challengeData = submitedChallengeResponse.challengeObject.challenge.data(using: .utf8)
        else { throw AuthenticateError.invalidSignatureError }
        let challengedDID = try castor.parseDID(str: submitedChallengeResponse.challengeObject.challengedDID)

        switch submitedChallengeResponse.response {
        case let .accept(signature):
            guard
                let signatureData = Base64Utils().decode(signature)
            else { throw AuthenticateError.invalidSignatureError }
            return try await castor.verifySignature(
                did: challengedDID,
                challenge: challengeData,
                signature: signatureData
            )
        case .refuse:
            throw AuthenticateError.challengeRefusedError
        }
    }
}
