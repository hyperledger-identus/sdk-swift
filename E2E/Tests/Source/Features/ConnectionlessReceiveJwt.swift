import TestFramework

final class ConnectionlessReceiveJwt: Feature {
    override var tags: [String] { ["credential", "jwt", "connectionless"] }
    override var title: String { "Receive connectionless jwt credential" }
    override var narrative: String {
        "The Edge Agent should be able to receive a jwt credential via a connectionless invitation"
    }
    
    func testReceiveOneCredential() async throws {
        currentScenario = Scenario("Receive one connectionless jwt credential")
            .given("Cloud Agent has a connectionless jwt credential offer invitation")
            .and("Cloud Agent shares invitation to Edge Agent")
            .when("Edge Agent connects through the invite")
            .then("Edge Agent should receive the credentials offer from Cloud Agent")
            .when("Edge Agent accepts the credentials offer from Cloud Agent")
            .then("Edge Agent wait to receive 1 issued credentials")
            .then("Edge Agent process issued credentials from Cloud Agent")
    }
}
