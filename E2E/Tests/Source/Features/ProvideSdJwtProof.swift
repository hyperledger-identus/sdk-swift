import TestFramework

final class ProvideSdJwtProof: Feature {
    override var tags: [String] { ["sdjwt", "proof"] }
    override var title: String { "Provide sdjwt proof" }
    override var narrative: String { "The Edge Agent should provide sdjwt proof to Cloud Agent" }
    
    func testRespondToProofOfRequest() async throws {
        currentScenario = Scenario("Respond to request proof")
            .given("Cloud Agent is connected to Edge Agent")
            .and("Edge Agent has '1' sdjwt credentials issued by Cloud Agent")
            .when("Cloud Agent asks for sdjwt present-proof")
            .and("Edge Agent sends the present-proof")
            .then("Cloud Agent should see the present-proof is verified")
    }
}
