import TestFramework

final class ReceiveSdJwtCredentialTests: Feature {
    override func title() -> String {
        "Receive verifiable credential"
    }
    
    override func description() -> String {
        "The Edge Agent should be able to receive a verifiable credential from Cloud Agent"
    }
    
    func testReceiveOneCredential() async throws {
        currentScenario = Scenario("Receive one sd+jwt credential")
            .given("Cloud Agent is connected to Edge Agent")
            .when("Cloud Agent offers '1' sd+jwt credentials")
            .then("Edge Agent should receive the credentials offer from Cloud Agent")
            .when("Edge Agent accepts the credentials offer from Cloud Agent")
            .when("Cloud Agent should see all credentials were accepted")
            .then("Edge Agent wait to receive 1 issued credentials")
            .and("Edge Agent process issued credentials from Cloud Agent")
    }
}
