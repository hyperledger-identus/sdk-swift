@testable import EdgeAgent
import Builders
import XCTest

final class PrismOnboardingInvitationTests: XCTestCase {
    func testWhenValidJsonInvitationThenReturn() throws {
        let example = PrismOnboardingInvitation.Body(
            type: ProtocolTypes.prismOnboarding.rawValue,
            onboardEndpoint: "localhost:8080",
            from: "someone"
        )

        let jsonString = try String(data: JSONEncoder().encode(example), encoding: .utf8)!

        let invitation = try PrismOnboardingInvitation(jsonString: jsonString)

        XCTAssertEqual(invitation.body.from, example.from)
        XCTAssertEqual(invitation.body.onboardEndpoint, example.onboardEndpoint)
        XCTAssertEqual(invitation.body.type, example.type)
    }

    func testWhenInvalidTypeInvitationThenReturn() throws {
        let example = PrismOnboardingInvitation.Body(
            type: "wrong type",
            onboardEndpoint: "localhost:8080",
            from: "someone"
        )

        let jsonString = try String(data: JSONEncoder().encode(example), encoding: .utf8)!

        XCTAssertThrowsError(try PrismOnboardingInvitation(jsonString: jsonString))
    }

    func testConnectionlessPresentationParsing() async throws {
        let connectionLessPresentation = "eyJpZCI6IjViMjUwMjIzLWExNDItNDRmYi1hOWJkLWU1MjBlNGI0ZjQzMiIsInR5cGUiOiJodHRwczovL2RpZGNvbW0ub3JnL291dC1vZi1iYW5kLzIuMC9pbnZpdGF0aW9uIiwiZnJvbSI6ImRpZDpwZWVyOjIuRXo2TFNkV0hWQ1BFOHc0NWZETjM4aUh0ZFJ6WGkyTFNqQmRSUjRGTmNOUm12VkNKcy5WejZNa2Z2aUI5S1F1OGlnNVZpeG1HZHM3dmdMNmoyUXNOUGFybkZaanBNQ0E5aHpQLlNleUowSWpvaVpHMGlMQ0p6SWpwN0luVnlhU0k2SW1oMGRIQTZMeTh4T1RJdU1UWTRMakV1TXpjNk9EQTNNQzlrYVdSamIyMXRJaXdpY2lJNlcxMHNJbUVpT2xzaVpHbGtZMjl0YlM5Mk1pSmRmWDAiLCJib2R5Ijp7ImdvYWxfY29kZSI6InByZXNlbnQtdnAiLCJnb2FsIjoiUmVxdWVzdCBwcm9vZiBvZiB2YWNjaW5hdGlvbiBpbmZvcm1hdGlvbiIsImFjY2VwdCI6W119LCJhdHRhY2htZW50cyI6W3siaWQiOiIyYTZmOGM4NS05ZGE3LTRkMjQtOGRhNS0wYzliZDY5ZTBiMDEiLCJtZWRpYV90eXBlIjoiYXBwbGljYXRpb24vanNvbiIsImRhdGEiOnsianNvbiI6eyJpZCI6IjI1NTI5MTBiLWI0NmMtNDM3Yy1hNDdhLTlmODQ5OWI5ZTg0ZiIsInR5cGUiOiJodHRwczovL2RpZGNvbW0uYXRhbGFwcmlzbS5pby9wcmVzZW50LXByb29mLzMuMC9yZXF1ZXN0LXByZXNlbnRhdGlvbiIsImJvZHkiOnsiZ29hbF9jb2RlIjoiUmVxdWVzdCBQcm9vZiBQcmVzZW50YXRpb24iLCJ3aWxsX2NvbmZpcm0iOmZhbHNlLCJwcm9vZl90eXBlcyI6W119LCJhdHRhY2htZW50cyI6W3siaWQiOiJiYWJiNTJmMS05NDUyLTQzOGYtYjk3MC0yZDJjOTFmZTAyNGYiLCJtZWRpYV90eXBlIjoiYXBwbGljYXRpb24vanNvbiIsImRhdGEiOnsianNvbiI6eyJvcHRpb25zIjp7ImNoYWxsZW5nZSI6IjExYzkxNDkzLTAxYjMtNGM0ZC1hYzM2LWIzMzZiYWI1YmRkZiIsImRvbWFpbiI6Imh0dHBzOi8vcHJpc20tdmVyaWZpZXIuY29tIn0sInByZXNlbnRhdGlvbl9kZWZpbml0aW9uIjp7ImlkIjoiMGNmMzQ2ZDItYWY1Ny00Y2E1LTg2Y2EtYTA1NTE1NjZlYzZmIiwiaW5wdXRfZGVzY3JpcHRvcnMiOltdfX19LCJmb3JtYXQiOiJwcmlzbS9qd3QifV0sInRoaWQiOiI1YjI1MDIyMy1hMTQyLTQ0ZmItYTliZC1lNTIwZTRiNGY0MzIiLCJmcm9tIjoiZGlkOnBlZXI6Mi5FejZMU2RXSFZDUEU4dzQ1ZkROMzhpSHRkUnpYaTJMU2pCZFJSNEZOY05SbXZWQ0pzLlZ6Nk1rZnZpQjlLUXU4aWc1Vml4bUdkczd2Z0w2ajJRc05QYXJuRlpqcE1DQTloelAuU2V5SjBJam9pWkcwaUxDSnpJanA3SW5WeWFTSTZJbWgwZEhBNkx5OHhPVEl1TVRZNExqRXVNemM2T0RBM01DOWthV1JqYjIxdElpd2ljaUk2VzEwc0ltRWlPbHNpWkdsa1kyOXRiUzkyTWlKZGZYMCJ9fX1dLCJjcmVhdGVkX3RpbWUiOjE3MjQzMzkxNDQsImV4cGlyZXNfdGltZSI6MTcyNDMzOTQ0NH0="

        let apollo = ApolloBuilder().build()
        let edgeAgent = EdgeAgent(
            apollo: apollo,
            castor: CastorBuilder(apollo: apollo).build(),
            pluto: MockPluto(),
            pollux: MockPollux(),
            seed: nil
        )
        let didcommAgent = DIDCommAgent(
            edgeAgent: edgeAgent,
            mercury: MockMercury(),
            mediationHandler: MockMediatorHandler())
        let result = try await didcommAgent.parseInvitation(str: connectionLessPresentation)
        switch result {
        case .connectionlessPresentation(let requestPresentation):
            break
        default:
            XCTFail("It should give a connectionless presentation request")
        }
    }

    func testConnectionlessIssuanceParsing() async throws {
        let connectionLessPresentation = "eyJpZCI6ImY5NmUzNjk5LTU5MWMtNGFlNy1iNWU2LTZlZmU2ZDI2MjU1YiIsInR5cGUiOiJodHRwczovL2RpZGNvbW0ub3JnL291dC1vZi1iYW5kLzIuMC9pbnZpdGF0aW9uIiwiZnJvbSI6ImRpZDpwZWVyOjIuRXo2TFNmc0tNZTh2U1NXa1lkWkNwbjRZVmlQRVJmZEdBaGRMQUdIZ3gyTEdKd2ZtQS5WejZNa3B3MWtTYWJCTXprQTN2NTl0UUZuaDNGdGtLeTZ4TGhMeGQ5UzZCQW9hQmcyLlNleUowSWpvaVpHMGlMQ0p6SWpwN0luVnlhU0k2SW1oMGRIQTZMeTh4T1RJdU1UWTRMakV1TXpjNk9EQTRNQzlrYVdSamIyMXRJaXdpY2lJNlcxMHNJbUVpT2xzaVpHbGtZMjl0YlM5Mk1pSmRmWDAiLCJib2R5Ijp7ImdvYWxfY29kZSI6Imlzc3VlLXZjIiwiZ29hbCI6IlRvIGlzc3VlIGEgRmFiZXIgQ29sbGVnZSBHcmFkdWF0ZSBjcmVkZW50aWFsIiwiYWNjZXB0IjpbImRpZGNvbW0vdjIiXX0sImF0dGFjaG1lbnRzIjpbeyJpZCI6IjcwY2RjOTBjLTlhOTktNGNkYS04N2ZlLTRmNGIyNTk1MTEyYSIsIm1lZGlhX3R5cGUiOiJhcHBsaWNhdGlvbi9qc29uIiwiZGF0YSI6eyJqc29uIjp7ImlkIjoiNjU1ZTlhMmMtNDhlZC00NTliLWIzZGEtNmIzNjg2NjU1NTY0IiwidHlwZSI6Imh0dHBzOi8vZGlkY29tbS5vcmcvaXNzdWUtY3JlZGVudGlhbC8zLjAvb2ZmZXItY3JlZGVudGlhbCIsImJvZHkiOnsiZ29hbF9jb2RlIjoiT2ZmZXIgQ3JlZGVudGlhbCIsImNyZWRlbnRpYWxfcHJldmlldyI6eyJ0eXBlIjoiaHR0cHM6Ly9kaWRjb21tLm9yZy9pc3N1ZS1jcmVkZW50aWFsLzMuMC9jcmVkZW50aWFsLWNyZWRlbnRpYWwiLCJib2R5Ijp7ImF0dHJpYnV0ZXMiOlt7Im5hbWUiOiJmYW1pbHlOYW1lIiwidmFsdWUiOiJXb25kZXJsYW5kIn0seyJuYW1lIjoiZ2l2ZW5OYW1lIiwidmFsdWUiOiJBbGljZSJ9LHsibmFtZSI6ImRyaXZpbmdDbGFzcyIsInZhbHVlIjoiTXc9PSIsIm1lZGlhX3R5cGUiOiJhcHBsaWNhdGlvbi9qc29uIn0seyJuYW1lIjoiZGF0ZU9mSXNzdWFuY2UiLCJ2YWx1ZSI6IjIwMjAtMTEtMTNUMjA6MjA6MzkrMDA6MDAifSx7Im5hbWUiOiJlbWFpbEFkZHJlc3MiLCJ2YWx1ZSI6ImFsaWNlQHdvbmRlcmxhbmQuY29tIn0seyJuYW1lIjoiZHJpdmluZ0xpY2Vuc2VJRCIsInZhbHVlIjoiMTIzNDUifV19fX0sImF0dGFjaG1lbnRzIjpbeyJpZCI6Ijg0MDQ2NzhiLTlhMzYtNDk4OS1hZjFkLTBmNDQ1MzQ3ZTBlMyIsIm1lZGlhX3R5cGUiOiJhcHBsaWNhdGlvbi9qc29uIiwiZGF0YSI6eyJqc29uIjp7Im9wdGlvbnMiOnsiY2hhbGxlbmdlIjoiYWQwZjQzYWQtODUzOC00MWQ0LTljYjgtMjA5NjdiYzY4NWJjIiwiZG9tYWluIjoiZG9tYWluIn0sInByZXNlbnRhdGlvbl9kZWZpbml0aW9uIjp7ImlkIjoiNzQ4ZWZhNTgtMmJjZS00NDBkLTkyMWYtMjUyMGE4NDQ2NjYzIiwiaW5wdXRfZGVzY3JpcHRvcnMiOltdLCJmb3JtYXQiOnsiand0Ijp7ImFsZyI6WyJFUzI1NksiXSwicHJvb2ZfdHlwZSI6W119fX19fSwiZm9ybWF0IjoicHJpc20vand0In1dLCJ0aGlkIjoiZjk2ZTM2OTktNTkxYy00YWU3LWI1ZTYtNmVmZTZkMjYyNTViIiwiZnJvbSI6ImRpZDpwZWVyOjIuRXo2TFNmc0tNZTh2U1NXa1lkWkNwbjRZVmlQRVJmZEdBaGRMQUdIZ3gyTEdKd2ZtQS5WejZNa3B3MWtTYWJCTXprQTN2NTl0UUZuaDNGdGtLeTZ4TGhMeGQ5UzZCQW9hQmcyLlNleUowSWpvaVpHMGlMQ0p6SWpwN0luVnlhU0k2SW1oMGRIQTZMeTh4T1RJdU1UWTRMakV1TXpjNk9EQTRNQzlrYVdSamIyMXRJaXdpY2lJNlcxMHNJbUVpT2xzaVpHbGtZMjl0YlM5Mk1pSmRmWDAifX19XSwiY3JlYXRlZF90aW1lIjoxNzI0ODUxMTM5LCJleHBpcmVzX3RpbWUiOjE3MjQ4NTE0Mzl9"

        let apollo = ApolloBuilder().build()
        let edgeAgent = EdgeAgent(
            apollo: apollo,
            castor: CastorBuilder(apollo: apollo).build(),
            pluto: MockPluto(),
            pollux: MockPollux(),
            seed: nil
        )
        let didcommAgent = DIDCommAgent(
            edgeAgent: edgeAgent,
            mercury: MockMercury(),
            mediationHandler: MockMediatorHandler())
        let result = try await didcommAgent.parseInvitation(str: connectionLessPresentation)
        switch result {
        case .connectionlessIssuance(let offerCredential):
            break
        default:
            XCTFail("It should give a connectionless presentation request")
        }
    }

//    func testLocal() async throws {
//        let example = PrismOnboardingInvitation.Body(
//            type: "https://atalaprism.io/did-request",
//            onboardEndpoint: "http://localhost:8070/onboard/fc16fa95-43e2-4313-a201-7bbca8d5641d",
//            from: "Goncalo Frade"
//        )
//
//        let jsonString = try String(data: JSONEncoder().encode(example), encoding: .utf8)!
//
//        let apollo = ApolloBuilder().build()
//        let castor = CastorBuilder(apollo: apollo).build()
//        let agent = EdgeAgent(
//            apollo: apollo,
//            castor: castor,
//            pluto: PlutoBuilder(setup: .init(coreDataSetup: .init(
//                modelPath: .storeName("PrismPluto"),
//                storeType: .memory
//            ))).build(),
//            mercury: MercuryBuilder(castor: castor).build()
//        )
//        let invitation = try await agent.parsePrismInvitation(str: jsonString)
//        do {
//            try await agent.acceptPrismInvitation(invitation: invitation)
//        } catch {
//            print(error)
//        }
//    }
}
