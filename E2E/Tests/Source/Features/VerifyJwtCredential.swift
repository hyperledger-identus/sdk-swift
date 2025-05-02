import TestFramework

final class VerifyJwt: Feature {
    override func title() -> String {
        "Verify JWT presentation"
    }
    
    override func description() -> String {
        "The Edge Agent should be able to receive a verifiable credential from Cloud Agent and then send a presentation to another edge agent who will verify it"
    }
    
    func testSdkJwtVerification() async throws {
        currentScenario = Scenario("Active credential should pass verification")
            .given("Cloud Agent is connected to Edge Agent")
            .and("Edge Agent has '1' jwt credentials issued by Cloud Agent")
            .then("Verifier Edge Agent requests Edge Agent to verify the JWT credential")
            .when("Edge Agent sends the present-proof")
            .then("Verifier Edge Agent should see the verification proof is verified")
    }
    
    func testSdkRevokedJwtVerification() async throws {
        currentScenario = Scenario("Revoked credential should fail verification")
            .given("Cloud Agent is connected to Edge Agent")
            .and("Edge Agent has '1' jwt credentials issued by Cloud Agent")
            .when("Cloud Agent revokes '1' credentials")
            .then("Edge Agent waits to receive the revocation notifications from Cloud Agent")
            .when("Verifier Edge Agent requests Edge Agent to verify the JWT credential")
            .and("Edge Agent sends the present-proof")
            .then("Verifier Edge Agent should see the verification proof is not verified")
    }
}
