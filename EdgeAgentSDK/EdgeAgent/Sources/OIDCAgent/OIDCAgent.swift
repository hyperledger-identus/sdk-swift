import Core
import Domain
import Foundation
//import OpenID4VCI
import JSONWebKey

public class OIDCAgent {
    public let edgeAgent: EdgeAgent
    public var apollo: Apollo & KeyRestoration { edgeAgent.apollo }
    public var castor: Castor { edgeAgent.castor }
    public var pluto: Pluto { edgeAgent.pluto }
    public var pollux: Pollux & CredentialImporter { edgeAgent.pollux }
    var logger: SDKLogger { edgeAgent.logger }

    /// Initializes a EdgeAgent with the given dependency objects and seed data.
    ///
    /// - Parameters:
    ///   - apollo: An instance of Apollo.
    ///   - castor: An instance of Castor.
    ///   - pluto: An instance of Pluto.
    ///   - pollux: An instance of Pollux.
    ///   - mercury: An instance of Mercury.
    ///   - seed: A unique seed used to generate the unique DID.
    ///   - mediatorServiceEnpoint: The endpoint of the Mediator service to use.
    public init(
        edgeAgent: EdgeAgent
    ) {
        self.edgeAgent = edgeAgent
    }

    /**
      Convenience initializer for `EdgeAgent` that allows for optional initialization of seed data and mediator service endpoint.

      - Parameters:
        - seedData: Optional seed data for creating a new seed. If not provided, a random seed will be generated.
        - mediatorServiceEnpoint: Optional DID representing the service endpoint of the mediator. If not provided, the default Prism mediator endpoint will be used.
    */
    public convenience init(
        seedData: Data? = nil
    ) {
        let edgeAgent = EdgeAgent(seedData: seedData)

        self.init(edgeAgent: edgeAgent)
    }

//    public func parseCredentialOffer(
//        offerUri: String
//    ) async throws -> CredentialOffer {
//        let result = try await CredentialOfferRequestResolver()
//            .resolve(source: .init(urlString: offerUri))
//        switch result {
//        case .success(let success):
//            return success
//        case .failure(let failure):
//            throw failure
//        }
//    }
//
//    public func createAuthorizationRequest(
//        clientId: String,
//        redirectUri: URL,
//        offer: CredentialOffer
//    ) async throws -> (Issuer, UnauthorizedRequest) {
//        let config = OpenId4VCIConfig(
//            clientId: clientId,
//            authFlowRedirectionURI: redirectUri,
//            authorizeIssuanceConfig: .favorScopes,
//            usePAR: false
//        )
//
//        guard let grants = offer.grants else {
//            throw EdgeAgentError.OIDCError.noGrantProvided
//        }
//
//        let issuer = try Issuer(
//            authorizationServerMetadata: offer.authorizationServerMetadata,
//            issuerMetadata: offer.credentialIssuerMetadata,
//            config: config
//        )
//
//        switch grants {
//        case .authorizationCode:
//            let parPlaced = try await issuer.pushAuthorizationCodeRequest(
//              credentialOffer: offer
//            )
//            switch parPlaced {
//            case .success(let success):
//                return (issuer, success)
//            case .failure(let failure):
//                throw EdgeAgentError.OIDCError.internalError(error: failure)
//            }
//        default:
//            throw EdgeAgentError.OIDCError.flowNotSupported
//        }
//    }
//
//    public func handleTokenRequest(
//        request: UnauthorizedRequest,
//        issuer: Issuer,
//        callbackUrl: URL
//    ) async throws -> (Issuer, AuthorizedRequest){
//        guard let components = URLComponents(url: callbackUrl, resolvingAgainstBaseURL: false) else {
//            throw EdgeAgentError.OIDCError.invalidCallbackURL
//        }
//        guard 
//            let queryItems = components.queryItems,
//            let code = queryItems.first(where: { $0.name == "code" })?.value
//        else {
//            throw EdgeAgentError.OIDCError.missingQueryParameters(parameters: ["code"])
//        }
//
//        let issuanceAuthorization: IssuanceAuthorization = .authorizationCode(authorizationCode: code)
//        let unAuthorized = await issuer.handleAuthorizationCode(
//            parRequested: request,
//            authorizationCode: issuanceAuthorization
//          )
//
//        switch unAuthorized {
//          case .success(let request):
//            let authorizedRequest = await issuer.requestAccessToken(authorizationCode: request)
//
//            if case let .success(authorized) = authorizedRequest {
//                return (issuer, authorized)
//            }
//
//          case .failure(let error):
//            throw EdgeAgentError.OIDCError.internalError(error: error)
//        }
//
//        throw UnknownError.somethingWentWrongError(customMessage: "OIDC Flow did not complete successfully", underlyingErrors: nil)
//
//    }
//
//    public func credentialRequest(
//        issuer: Issuer,
//        offer: CredentialOffer,
//        request: AuthorizedRequest
//    ) async throws -> Credential {
//        let payload: IssuanceRequestPayload = .configurationBased(
//            credentialConfigurationIdentifier: offer.credentialConfigurationIdentifiers.first!,
//            claimSet: nil
//        )
//
//        let did = try await createNewPrismDID()
//
//        guard 
//            let keys = try await pluto.getDIDPrivateKeys(did: did).first().await(),
//            let key = try await keys.first.asyncMap({ try await apollo.restorePrivateKey($0) }),
//            let exported = key.exporting?.jwkWithKid(kid: did.string + "#authentication0")
//        else {
//            throw EdgeAgentError.cannotFindDIDKeyPairIndex
//        }
//
//        let privateJwk = try exported.toJoseJWK()
//        let result = try await issuer.requestSingle(
//            proofRequest: request,
//            bindingKey: .jwk(
//                algorithm: .init(name: "ES256K"),
//                jwk: privateJwk.publicKey,
//                privateKey: privateJwk,
//                issuer: did.string
//            ),
//            requestPayload: payload) { issuerResponseEncryptionMetadata in
//                Issuer.createResponseEncryptionSpec(issuerResponseEncryptionMetadata)
//            }
//
//        switch result {
//        case .success(let success):
//            switch success {
//            case .success(let response):
//                guard let credential = response.credentialResponses.first else {
//                    throw UnknownError.somethingWentWrongError(customMessage: nil, underlyingErrors: nil)
//                }
//                switch credential {
//                case .deferred:
//                    throw EdgeAgentError.OIDCError.crendentialResponseDeferredNotSupported
//                case .issued(let credential, _):
//                    let parsedCredential = try await pollux.importCredential(
//                        credentialData: credential.tryToData(),
//                        restorationType: "jwt",
//                        options: []
//                    )
//                    if let storableCredential = parsedCredential.storable {
//                        try await pluto.storeCredential(credential: storableCredential).first().await()
//                    }
//
//                    return parsedCredential
//                }
//            case .failed(let error):
//                throw EdgeAgentError.OIDCError.internalError(error: error)
//            case .invalidProof(_, let errorDescription):
//                throw EdgeAgentError.OIDCError.invalidProof(errorDescription: errorDescription)
//            }
//        case .failure(let failure):
//            throw EdgeAgentError.OIDCError.internalError(error: failure)
//        }
//    }
}
