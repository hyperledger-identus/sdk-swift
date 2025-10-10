import TestFramework

final class ReceiveAnoncredCredential: Feature {
    override var tags: [String] { ["credential", "anoncred"] }
    override var title: String { "Receive anonymous credential" }
    override var narrative: String { "The Edge Agent should be able to receive an anonymous credential from Cloud Agent" }
    
    func testReceiveOneAnoncred() async throws {
        currentScenario = Scenario("Receive one anonymous credential")
            .given("Cloud Agent is connected to Edge Agent")
            .when("Cloud Agent offers '1' anonymous credentials")
            .then("Edge Agent should receive the credentials offer from Cloud Agent")
            .when("Edge Agent accepts the credentials offer from Cloud Agent")
            .when("Cloud Agent should see all credentials were accepted")
            .then("Edge Agent wait to receive 1 issued credentials")
            .then("Edge Agent process issued credentials from Cloud Agent")
    }
}
