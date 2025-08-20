import AnoncredsSwift
@testable import Pollux
import XCTest

final class AnoncredsTests: XCTestCase {
    let pluto = MockPluto()
    let castor = MockCastor()
    let issuer = MockIssuer()
    var linkSecret: LinkSecret!

    override func setUp() async throws {
        linkSecret = try LinkSecret.newFromValue(valueString: "65965334953670062552662719679603258895632947953618378932199361160021795698890")
    }

    func testCreateMessageRequest() async throws {
        let offer = try issuer.createOfferMessage()
        let linkSecretValue = try linkSecret.getValue()
        let credDef = issuer.credDef
        let defDownloader = MockDownloader(returnData: try credDef.getJson().data(using: .utf8)!)

        // No error means it passed
        _ = try await PolluxImpl(castor: castor, pluto: pluto).processCredentialRequest(
            offerMessage: offer,
            options: [
                .linkSecret(id: "test", secret: linkSecretValue),
                .credentialDefinitionDownloader(downloader: defDownloader),
                .subjectDID(.init(method: "test", methodId: "adasdadde"))
            ]
        )
    }

    func testParseIssueCredential() async throws {
        let offer = try issuer.createOffer()
        let linkSecretValue = try linkSecret.getValue()

        let credDef = issuer.credDef
        let defDownloader = MockDownloader(returnData: try credDef.getJson().data(using: .utf8)!)
        let schemaDownloader = MockDownloader(returnData: issuer.getSchemaJson().data(using: .utf8)!)
        let prover = MockProver(linkSecret: linkSecret, credDef: credDef)
        let request = try prover.createRequest(offer: offer)
        let credentialMetadata = try StorableCredentialRequestMetadata(
            metadataJson: request.1.getJson().tryData(using: .utf8),
            storingId: "1"
        )
        try await pluto.storeCredential(credential: credentialMetadata).first().await()
        let issuedMessage = try issuer.issueCredential(offer: offer, request: request.0)
        let credential = try await PolluxImpl(castor: castor, pluto: pluto).parseCredential(
            issuedCredential: issuedMessage,
            options: [
                .linkSecret(id: "test", secret: linkSecretValue),
                .credentialDefinitionDownloader(downloader: defDownloader),
                .schemaDownloader(downloader: schemaDownloader)
            ]
        )

        XCTAssertTrue(credential.claims.contains(where: { $0.key == "name" }))
        XCTAssertTrue(credential.claims.contains(where: { $0.key == "sex" }))
        XCTAssertTrue(credential.claims.contains(where: { $0.key == "age" }))
        XCTAssertEqual(credential.claims.first(where: { $0.key == "name" })?.getValueAsString(), "Miguel")
    }


    func testProvingCredential() async throws {
        let offer = try issuer.createOffer()
        let linkSecretValue = try linkSecret.getValue()

        let credDef = issuer.credDef
        let defDownloader = MockDownloader(returnData: try credDef.getJson().data(using: .utf8)!)
        let schemaDownloader = MockDownloader(returnData: issuer.getSchemaJson().data(using: .utf8)!)
        let prover = MockProver(linkSecret: linkSecret, credDef: credDef)
        let request = try prover.createRequest(offer: offer)
        let credentialMetadata = try StorableCredentialRequestMetadata(
            metadataJson: request.1.getJson().tryData(using: .utf8),
            storingId: "1"
        )
        try await pluto.storeCredential(credential: credentialMetadata).first().await()
        let issuedMessage = try issuer.issueCredential(offer: offer, request: request.0)
        let credential = try await PolluxImpl(castor: castor, pluto: pluto).parseCredential(
            issuedCredential: issuedMessage,
            options: [
                .linkSecret(id: "test", secret: linkSecretValue),
                .credentialDefinitionDownloader(downloader: defDownloader),
                .schemaDownloader(downloader: schemaDownloader)
            ]
        )
        XCTAssertTrue(credential.isProofable)

        let presentationRequest = try issuer.createPresentationRequest()

        let presentation = try await credential.proof!.presentation(
            request: presentationRequest.message,
            options: [
                .linkSecret(id: "", secret: issuer.linkSecret.getValue()),
            ]
        )

        let value = try issuer.verifyPresentation(presentation: presentation, request: presentationRequest.requestStr)
        XCTAssertTrue(value)
    }
}
