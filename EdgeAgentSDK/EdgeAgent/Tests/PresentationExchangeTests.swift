import Builders
import Core
import Domain
import Logging
import JSONWebSignature
import JSONWebToken
@testable import EdgeAgent
@testable import Pollux
import XCTest

final class PresentationExchangeFlowTests: XCTestCase {
    var apollo: Apollo & KeyRestoration = ApolloBuilder().build()
    var pluto = MockPluto()
    var castor: Castor!
    var pollux: (Pollux & CredentialImporter)!
    var mercury = MercuryStub()
    var edgeAgent: EdgeAgent!
    let logger = Logger(label: "presentation_exchange_test")

    override func setUp() async throws {
        castor = CastorBuilder(apollo: apollo).build()
        pollux = PolluxBuilder(pluto: pluto, castor: castor).build()
        edgeAgent = EdgeAgent(
            apollo: apollo,
            castor: castor,
            pluto: pluto,
            pollux: pollux,
            mercury: mercury
        )
    }

    func testJWTPresentationRequest() async throws {
        let prismDID = try await edgeAgent.createNewPrismDID()
        let subjectDID = try await edgeAgent.createNewPrismDID()

        let jwt = try await makeCredentialJWT(issuerDID: prismDID, subjectDID: subjectDID)
        let credential = try JWTCredential(data: jwt.tryToData())

        logger.info("Creating presentation request")
        let message = try await edgeAgent.initiatePresentationRequest(
            type: .jwt,
            fromDID: DID(method: "test", methodId: "alice"),
            toDID: DID(method: "test", methodId: "bob"),
            claimFilters: [
                .init(
                    paths: ["$.vc.credentialSubject.test"],
                    type: "string",
                    required: true,
                    pattern: "aliceTest"
                )
            ]
        )

        try await edgeAgent.pluto.storeMessage(message: message.makeMessage(), direction: .sent).first().await()

        let presentation = try await edgeAgent.createPresentationForRequestProof(
            request: message,
            credential: credential
        )

        let verification = try await edgeAgent.pollux.verifyPresentation(
            message: presentation.makeMessage(),
            options: []
        )

        logger.info(verification ? "Verification was successful" : "Verification failed")
        XCTAssertTrue(verification)
    }

    func testJWTPresentationFailureToComplyRequest() async throws {
        let message = try await edgeAgent.initiatePresentationRequest(
            type: .jwt,
            fromDID: DID(method: "test", methodId: "alice"),
            toDID: DID(method: "test", methodId: "bob"),
            claimFilters: [
                .init(
                    paths: ["$.vc.credentialSubject.invalidField"],
                    type: "string"
                )
            ]
        )

        try await edgeAgent.pluto.storeMessage(message: message.makeMessage(), direction: .sent).first().await()

        let prismDID = try await edgeAgent.createNewPrismDID()
        let subjectDID = try await edgeAgent.createNewPrismDID()

        let jwt = try await makeCredentialJWT(issuerDID: prismDID, subjectDID: subjectDID)
        let credential = try JWTCredential(data: jwt.tryToData())

        do {
            _ = try await edgeAgent.createPresentationForRequestProof(
                request: message,
                credential: credential
            )
            XCTFail()
        } catch {
            print("Success credential doesnt provide the $.vc.credentialSubject.invalidField: \(error)")
        }
    }

    private func makeCredentialJWT(issuerDID: DID, subjectDID: DID) async throws -> String {
        let payload = MockCredentialClaim(
            iss: issuerDID.string,
            sub: subjectDID.string,
            aud: nil,
            exp: nil,
            nbf: nil,
            iat: nil,
            jti: nil,
            vc: .init(credentialSubject: ["test": "aliceTest"])
        )

        let jwsHeader = DefaultJWSHeaderImpl(algorithm: .ES256K)
        guard 
            let key = try await edgeAgent.pluto.getDIDPrivateKeys(did: issuerDID).first().await()?.first,
            let jwkD = try await edgeAgent.apollo.restorePrivateKey(key).exporting?.jwk
        else {
            XCTFail()
            fatalError()
        }
        return try JWT.signed(payload: payload, protectedHeader: jwsHeader, key: jwkD.toJoseJWK()).jwtString
    }
}

private struct MockCredentialClaim: JWTRegisteredFieldsClaims {
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
