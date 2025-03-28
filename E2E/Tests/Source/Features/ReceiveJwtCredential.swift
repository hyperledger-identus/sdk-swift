import TestFramework

final class ReceiveJwtCredentialTests: Feature {
    override func title() -> String {
        "Receive verifiable credential"
    }
    
    override func description() -> String {
        "The Edge Agent should be able to receive a verifiable credential from Cloud Agent"
    }
    
    func testReceiveOneCredential() async throws {
        currentScenario = Scenario("Receive one verifiable credential")
            .given("Cloud Agent is connected to Edge Agent")
            .when("Cloud Agent offers '1' jwt credentials")
            .then("Edge Agent should receive the credentials offer from Cloud Agent")
            .when("Edge Agent accepts the credentials offer from Cloud Agent")
            .when("Cloud Agent should see all credentials were accepted")
            .then("Edge Agent wait to receive 1 issued credentials")
            .then("Edge Agent process issued credentials from Cloud Agent")
    }
    
    func testReceiveMultipleCredentialsSequentially() async throws {
        currentScenario = Scenario("Receive multiple verifiable credentials sequentially")
            . given("Cloud Agent is connected to Edge Agent")
            .when("Edge Agent accepts 3 jwt credential offer sequentially from Cloud Agent")
            .then("Cloud Agent should see all credentials were accepted")
            .and("Edge Agent wait to receive 3 issued credentials")
            .and("Edge Agent process issued credentials from Cloud Agent")
    }
    
    func testReceiveMultipleCredentialsAtOnce() async throws {
        currentScenario = Scenario("Receive multiple verifiable credentials at once")
            .given("Cloud Agent is connected to Edge Agent")
            .when("Edge Agent accepts 3 jwt credentials offer at once from Cloud Agent")
            .then("Cloud Agent should see all credentials were accepted")
            .and("Edge Agent wait to receive 3 issued credentials")
            .and("Edge Agent process issued credentials from Cloud Agent")
    }
}
