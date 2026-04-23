import XCTest
import Domain
@testable import EdgeAgent
@testable import Pollux
import Apollo
import Castor
import Pluto
import Mercury
import Combine

/**
 * E2E tests for the connectionless presentation flow.
 * These tests verify that the EdgeAgent can process presentation requests shared via OOB invitations
 * without establishing a persistent DID connection (DIDPair).
 */
final class ConnectionlessPresentationTests: XCTestCase {
    var verifier: DIDCommAgent!
    var holder: DIDCommAgent!
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() async throws {
        // Initialize agents with different seeds
        verifier = try await createAgent(seed: .init(value: Data(repeating: 1, count: 64)))
        holder = try await createAgent(seed: .init(value: Data(repeating: 2, count: 64)))
        
        // Start agents
        try await verifier.start()
        try await holder.start()
    }
    
    override func tearDown() async throws {
        try await verifier.stop()
        try await holder.stop()
        cancellables.removeAll()
    }
    
    /**
     * Helper to create a localized Agent instance for testing.
     */
    private func createAgent(seed: Seed) async throws -> DIDCommAgent {
        let apollo = ApolloBuilder().build()
        let castor = CastorBuilder(apollo: apollo).build()
        let pluto = PlutoBuilder(setup: .init(
            coreDataSetup: .init(modelPath: .storeName("TestPluto-\(UUID().uuidString)"), storeType: .memory),
            keychain: KeychainMock()
        )).build()
        let pollux = PolluxBuilder(pluto: pluto, castor: castor).build()
        
        // Mock Mercury secrets stream
        let mercury = MercuryBuilder(
            castor: castor,
            secretsStream: Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
        ).build()
        
        let edgeAgent = EdgeAgent(
            apollo: apollo,
            castor: castor,
            pluto: pluto,
            pollux: pollux,
            seed: seed
        )
        
        // We use a DIDCommAgent wrapper which handles higher-level protocols
        return DIDCommAgent(edgeAgent: edgeAgent, mercury: mercury)
    }

    /**
     * Test Case 1: Valid connectionless presentation flow.
     */
    func testSuccessfulConnectionlessPresentation() async throws {
        // 1. Verifier creates a presentation request (initially addressed to a placeholder)
        let verifierDid = try await verifier.createNewPeerDID()
        let presentationRequest = try await verifier.initiatePresentationRequest(
            type: .jwt,
            fromDID: verifierDid,
            toDID: try DID(string: "did:peer:placeholder"),
            claimFilters: []
        )
        
        // 2. Wrap request in an OutOfBand invitation (simulating QR code or deep link)
        let invitation = OutOfBandInvitation(
            id: UUID().uuidString,
            body: .init(goalCode: "presentation", goal: "verify", accept: ["didcomm/v2"]),
            from: verifierDid,
            attachments: presentationRequest.makeMessage().attachments
        )
        
        // 3. Holder processes invitation
        let invitationData = try JSONEncoder.didComm().encode(invitation)
        let invitationString = String(data: invitationData, encoding: .utf8)!
        
        // Use parseInvitation which automatically identifies connectionless flows
        let invitationType = try await holder.parseInvitation(str: invitationString)
        
        guard case .connectionlessPresentation(let request) = invitationType else {
            XCTFail("Invitation should have been recognized as a connectionless presentation request")
            return
        }
        
        // ASSERT: Ensure NO DID connection (DIDPair) was established
        let didPairs = try await holder.pluto.getAllDidPairs().first().await()
        XCTAssertTrue(didPairs.isEmpty, "Connectionless flow must NOT establish a persistent DID connection")
        
        // ASSERT: Ensure the message was stored in Pluto via the parseInvitation flow
        let messages = try await holder.pluto.getAllMessages().first().await()
        XCTAssertTrue(messages.contains(where: { $0.id == request.id }), "Request message was not stored in Pluto")

        // 4. Verification Logic
        // In this local E2E, we verify that the generated presentation is valid
        // We mock a credential for this specific test case
        let mockCredential = try await Fixtures.createMockJWTCredential(apollo: holder.apollo)
        
        let presentation = try await holder.createPresentationForRequestProof(
            request: request,
            credential: mockCredential
        )
        
        // Verify via Verifier
        let isValid = try await verifier.verifyPresentation(message: presentation.makeMessage())
        XCTAssertTrue(isValid, "Verifier should successfully verify the connectionless presentation")
    }

    /**
     * Test Case 2: Verification should fail if the request is tampered.
     */
    func testTamperedRequestFails() async throws {
        let verifierDid = try await verifier.createNewPeerDID()
        let presentationRequest = try await verifier.initiatePresentationRequest(
            type: .jwt,
            fromDID: verifierDid,
            toDID: try DID(string: "did:peer:placeholder"),
            claimFilters: []
        )
        
        // TAMPER: Manually modify the request ID or goal_code to break integrity
        let tamperedBody = PresentationId(
            proofTypes: presentationRequest.body.proofTypes,
            goalCode: "TAMPERED_GOAL",
            comment: presentationRequest.body.comment
        )
        
        let tamperedRequest = RequestPresentation(
            body: tamperedBody,
            attachments: presentationRequest.attachments,
            thid: presentationRequest.thid,
            from: presentationRequest.from,
            to: presentationRequest.to
        )
        
        let mockCredential = try await Fixtures.createMockJWTCredential(apollo: holder.apollo)
        
        // Holder creates presentation based on tampered request
        let presentation = try await holder.createPresentationForRequestProof(
            request: tamperedRequest,
            credential: mockCredential
        )
        
        // Verifier should reject this presentation
        let isValid = try await verifier.verifyPresentation(message: presentation.makeMessage())
        XCTAssertFalse(isValid, "Verifier MUST detect tampering in the presentation request metadata")
    }

    /**
     * Test Case 3: Generation fails if required credentials are missing.
     */
    func testMissingCredentialsFails() async throws {
        let verifierDid = try await verifier.createNewPeerDID()
        // Request AnonCreds while holder only has the ability to provide JWT in this test setup
        let presentationRequest = try await verifier.initiatePresentationRequest(
            type: .anoncred,
            fromDID: verifierDid,
            toDID: try DID(string: "did:peer:placeholder"),
            claimFilters: []
        )
        
        let mockJWTCredential = try await Fixtures.createMockJWTCredential(apollo: holder.apollo)
        
        // Assert that creating a presentation for an incompatible type throws
        do {
            _ = try await holder.createPresentationForRequestProof(
                request: presentationRequest,
                credential: mockJWTCredential
            )
            XCTFail("Should have thrown an error for incompatible credential type")
        } catch {
            // Success - error was thrown
            XCTAssertNotNil(error)
        }
    }
}

/**
 * Mock fixtures to support local E2E testing without full network stack
 */
private enum Fixtures {
    static func createMockJWTCredential(apollo: Apollo) async throws -> Credential {
        // Minimal JWT credential mock
        return Credential(
            id: UUID().uuidString,
            recoveryId: nil,
            isRevoked: false,
            properties: ["format": "prism/jwt"],
            storable: nil // E2E locally can use memory objects
        )
    }
}

/**
 * Helper to mock Keyboard/Keychain dependencies in tests
 */
private final class KeychainMock: Keychain {
    private var store: [String: Data] = [:]
    func save(data: Data, forKey key: String) throws { store[key] = data }
    func read(forKey key: String) throws -> Data? { return store[key] }
    func delete(forKey key: String) throws { store.removeValue(forKey: key) }
}
