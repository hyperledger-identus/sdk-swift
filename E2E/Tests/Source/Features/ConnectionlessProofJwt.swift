import TestFramework

final class ConnectionlessProofJwt: Feature {
    override var tags: [String] { ["jwt", "proof", "connectionless"] }
    override var title: String { "Provide connectionless jwt proof" }
    override var narrative: String {
        "The Edge Agent should provide jwt proof to Cloud Agent via a connectionless invitation"
    }
    
    func testRespondToProofOfRequest() async throws {
        currentScenario = Scenario("Respond to connectionless request proof")
            .given("Edge Agent has '1' connectionless jwt credentials issued by Cloud Agent")
            .when("Cloud Agent has a connectionless jwt verification invite")
            .and("Cloud Agent shares invitation to Edge Agent")
            .and("Edge Agent connects through the invite")
            .and("Edge Agent sends the present-proof")
            .then("Cloud Agent should see the present-proof is verified")
    }
}
