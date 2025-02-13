import TestFramework

final class ConnectionFeature: Feature {
    override func title() -> String {
        "Create connection"
    }
    
    override func description() -> String {
        "The Edge Agent should be able to create a connection to Open Enterprise Agent"
    }
    
    func testConnection() async throws {
        currentScenario = Scenario("Create connection between Cloud and Edge agents")
            .given("Cloud Agent has a connection invitation")
            .given("Cloud Agent shares invitation to Edge Agent")
            .when("Edge Agent connects through the invite")
            .then("Cloud Agent should have the connection status updated to 'ConnectionResponseSent'")
    }
}
