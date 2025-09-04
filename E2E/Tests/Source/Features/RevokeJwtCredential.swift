import TestFramework

final class RevokeJwtCredential: Feature {
    override var tags: [String] { ["revocation", "jwt"] }
    override var title: String { "Revoke JWT Credential" }
    override var narrative: String { "Edge Agent should be notified when Cloud Agent revokes a credential" }
    
    func testRevocationNotification() async throws {
        currentScenario = Scenario("Revoke one verifiable credential")
            .given("Cloud Agent is connected to Edge Agent")
            .and("Edge Agent has '1' jwt credentials issued by Cloud Agent")
            .when("Cloud Agent revokes '1' credentials")
            .then("Edge Agent waits to receive the revocation notifications from Cloud Agent")
            .and("Edge Agent should see the credentials were revoked by Cloud Agent")
    }
}
