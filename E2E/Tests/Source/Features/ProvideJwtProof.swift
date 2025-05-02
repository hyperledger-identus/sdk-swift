import TestFramework

final class ProvideJwtProof: Feature {
    override func title() -> String {
        "Provide jwt proof"
    }
    
    override func description() -> String {
        "The Edge Agent should provide jwt proof to Cloud Agent"
    }
    
    func testRespondToProofOfRequest() async throws {
        currentScenario = ParameterizedScenario("Respond to request proof")
            .given("Cloud Agent is connected to Edge Agent")
            .and("Edge Agent has '1' jwt credentials issued by Cloud Agent")
            .when("Cloud Agent asks for jwt present-proof")
            .and("Edge Agent sends the present-proof")
            .then("Cloud Agent should see the present-proof is verified")
    }
}
