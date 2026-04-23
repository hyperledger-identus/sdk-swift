import XCTest
import Domain
import Mercury
import Pluto
import Combine
@testable import EdgeAgent

final class ConnectionlessIssuanceTests: XCTestCase {
    var issuer: DIDCommAgent!
    var holder: DIDCommAgent!

    override func setUp() async throws {
        let apollo = ApolloBuilder().build()
        let castor = CastorBuilder(apollo: apollo).build()
        
        // Using MockPluto (Available in EdgeAgentTests target)
        let issuerPluto = MockPluto()
        let holderPluto = MockPluto()
        
        let issuerEdge = EdgeAgent(
            apollo: apollo,
            castor: castor,
            pluto: issuerPluto,
            pollux: PolluxBuilder(pluto: issuerPluto, castor: castor).build()
        )
        let holderEdge = EdgeAgent(
            apollo: apollo,
            castor: castor,
            pluto: holderPluto,
            pollux: PolluxBuilder(pluto: holderPluto, castor: castor).build()
        )
        
        // Real SDK initialization requires link secret setup for certain protocol flows
        try await issuerEdge.firstLinkSecretSetup()
        try await holderEdge.firstLinkSecretSetup()
        
        issuer = DIDCommAgent(edgeAgent: issuerEdge)
        holder = DIDCommAgent(edgeAgent: holderEdge)
    }

    func testSuccessfulConnectionlessIssuance() async throws {
        // 1. Setup DIDs
        let issuerDID = try await issuer.createNewPrismDID()
        let holderDID = try await holder.createNewPrismDID()

        // 2. Issuer creates credential offer
        let preview = CredentialPreview3_0(
            schemaId: "https://schema.org/Person",
            attributes: [
                .init(name: "name", value: "Alice", mediaType: "text/plain")
            ]
        )
        
        let attachment = AttachmentDescriptor.build(
            data: AttachmentJsonData(json: ["name": "Alice"]),
            format: "prism/jwt"
        )
        
        let offer = OfferCredential3_0(
            id: UUID().uuidString,
            body: .init(goalCode: "issue-vc", credentialPreview: preview),
            type: ProtocolTypes.didcommOfferCredential3_0.rawValue,
            attachments: [attachment],
            thid: UUID().uuidString,
            from: issuerDID,
            to: DID(index: 999) // Placeholder DID for OOB invitation
        )

        // 3. Wrap offer in Out-of-Band invitation
        let offerMessage = try offer.makeMessage()
        let offerJson = try JSONSerialization.jsonObject(with: try JSONEncoder.didComm().encode(offerMessage)) as! [String: Any]
        
        // OutOfBandInvitation is only Decodable in this SDK version, so we construct the JSON dictionary manually
        let oobDictionary: [String: Any] = [
            "id": UUID().uuidString,
            "type": ProtocolTypes.didcomminvitation.rawValue,
            "from": issuerDID.string,
            "body": [
                "goal_code": "issue-vc",
                "goal": "Issue Credential",
                "accept": ["didcomm/v2"]
            ],
            "attachments": [
                [
                    "id": UUID().uuidString,
                    "media_type": "application/json",
                    "data": ["json": offerJson]
                ]
            ]
        ]
        
        let oobData = try JSONSerialization.data(withJSONObject: oobDictionary)
        let invitationString = oobData.base64UrlEncodedString()

        // 4. Holder processes invitation
        let result = try await holder.parseInvitation(str: invitationString)

        // 5. ASSERT: result is ConnectionlessCredentialOffer
        guard case .connectionlessIssuance(let extractedOffer) = result else {
            XCTFail("Result should be connectionlessIssuance")
            return
        }

        // 6. Extract offer and ensure it's valid
        XCTAssertEqual(extractedOffer.from.string, issuerDID.string)

        // 7. Validate connectionless: No DIDPair (connection) created in Pluto
        let didPairs = try await holder.pluto.getAllDidPairs().first().await()
        XCTAssertTrue(didPairs.isEmpty, "No DID pairs should be created for connectionless issuance")

        // 8. Holder prepares request
        guard let request = try await holder.prepareRequestCredentialWithIssuer(
            did: holderDID,
            offer: extractedOffer
        ) else {
            XCTFail("Request preparation failed")
            return
        }

        // 9. Issuer issues credential (Simulating issuer response based on received request)
        let issue = try IssueCredential3_0.makeIssueFromRequestCredential(msg: try request.makeMessage())

        // 10. Holder processes issued credential message
        _ = try await holder.processIssuedCredentialMessage(message: issue)

        // 11. ASSERT: Credential must be stored in Holder's Pluto database
        let credentials = try await holder.pluto.getAllCredentials().first().await()
        XCTAssertFalse(credentials.isEmpty, "Credential should be stored in Pluto")
        XCTAssertEqual(credentials.count, 1)
    }

    func testTamperedOfferFails() async throws {
        let issuerDID = try await issuer.createNewPrismDID()
        
        // Create an invitation with a corrupt message in attachment
        let tamperedOobDict: [String: Any] = [
            "id": UUID().uuidString,
            "type": ProtocolTypes.didcomminvitation.rawValue,
            "from": issuerDID.string,
            "body": [ "goal_code": "issue-vc" ],
            "attachments": [
                [
                    "id": UUID().uuidString,
                    "media_type": "application/json",
                    "data": ["json": ["id": "corrupt-message", "piuri": "invalid"]]
                ]
            ]
        ]
        
        let invitationString = try JSONSerialization.data(withJSONObject: tamperedOobDict).base64UrlEncodedString()
        
        // Attempting to parse should fail during the extraction of the connectionless offer
        do {
            _ = try await holder.parseInvitation(str: invitationString)
            XCTFail("Should have thrown error due to invalid offer content")
        } catch {
            // Success: error thrown
        }
    }

    func testInvalidInvitationFails() async throws {
        // OOB invitation without any attachments
        let oobDictionary: [String: Any] = [
            "id": UUID().uuidString,
            "type": ProtocolTypes.didcomminvitation.rawValue,
            "from": "did:prism:issuer",
            "body": [ "goal_code": "unknown" ]
        ]
        
        let invitationString = try JSONSerialization.data(withJSONObject: oobDictionary).base64UrlEncodedString()
        let result = try await holder.parseInvitation(str: invitationString)
        
        if case .connectionlessIssuance = result {
            XCTFail("Should not recognize invitation without attachments as connectionless issuance")
        }
    }
}
