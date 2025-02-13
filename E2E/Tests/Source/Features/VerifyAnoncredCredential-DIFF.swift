import TestFramework

final class AnoncredVerification: Feature {
    override func title() -> String {
        "Verify Anoncred presentation"
    }
    
    override func description() -> String {
        "The Edge Agent should be able to receive a verifiable credential from Cloud Agent and then send a presentation to another edge agent who will verify it"
    }
    
    func testSdkAnoncredVerification() async throws {
        currentScenario = Scenario("SDKs Anoncreds Verification")
            .given("Cloud Agent is connected to Edge Agent")
            .and("Edge Agent has '1' anonymous credentials issued by Cloud Agent")
            .when("Verifier Edge Agent will request Edge Agent to verify the anonymous credential")
            .and("Edge Agent sends the present-proof")
            .then("Verifier Edge Agent should see the verification proof is verified")
    }

    func testSdkAnoncredVerificationUnsatisfiedPredicate() async throws {
        currentScenario = Scenario("SDKs Anoncreds Verification")
            .given("Cloud Agent is connected to Edge Agent")
            .and("Edge Agent has '1' anonymous credentials issued by Cloud Agent")
            .when("Verifier Edge Agent will request Edge Agent to verify the anonymous credential for age greater than actual")
            .then("Edge Agent should not be able to create the present-proof")
    }
}
