import TestFramework

final class AnoncredProofOfRequestFeature: Feature {
    override func title() -> String {
        "Provide anonymous proof of request"
    }
    
    override func description() -> String {
        "The Edge Agent should provide anonymous proof to Cloud Agent"
    }
    
    func testRespondToProofOfRequest() async throws {
        currentScenario = Scenario("Respond to anonymous request proof")
            .given("Cloud Agent is connected to Edge Agent")
            .and("Edge Agent has '1' anonymous credentials issued by Cloud Agent")
            .when("Cloud Agent asks for anonymous present-proof")
            .and("Edge Agent sends the present-proof")
            .then("Cloud Agent should see the present-proof is verified")
    }
    
    func testRespondToAPresentRequestWithWrongCredential() async throws {
        currentScenario = Scenario("Respond to a present request with a wrong credential")
            .given("Cloud Agent is connected to Edge Agent")
            .and("Edge Agent has '1' anonymous credentials issued by Cloud Agent")
            .when("Cloud Agent asks for anonymous present-proof with unexpected attributes")
            .then("Edge Agent should receive an exception when trying to use a wrong anoncred credential")
    }
    
//    func testRespondToAPresentRequestWithWrongAttribute() async throws {
//        currentScenario = Scenario("Respond to a present request with a wrong attribute")
//            .given("Cloud Agent is connected to Edge Agent")
//            .and("Edge Agent has '1' anonymous credentials issued by Cloud Agent")
//            .when("Cloud Agent asks for presentation of AnonCred proof with unexpected values")
//            .and("Edge Agent sends the present-proof")
//            .then("Cloud Agent should see the present-proof is not verified")
//    }
    
}
