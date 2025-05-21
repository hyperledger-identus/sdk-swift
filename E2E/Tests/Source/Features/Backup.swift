import Foundation
import TestFramework

final class BackupFeature: Feature {
    override func title() -> String {
        "Backup"
    }
    
    override func description() -> String {
        "The Edge Agent should be able to create and restore a backup"
    }
    
    func testCreateAndRestoreABackup() async throws {
        currentScenario = Scenario("Create and restore a backup")
            .given("Edge Agent has created a backup")
            .then("a new Restored Agent can be restored from Edge Agent")
    }
    
    func testAgentWithoutProperSeedShouldNotBeAbleToRestoreTheBackup() async throws {
        currentScenario = Scenario("Agent without a seed should not be able to restore the backup")
            .given("Edge Agent has created a backup")
            .then("a new Restored Agent cannot be restored from Edge Agent with wrong seed")
    }

    func testRestoredBackupShouldBeFunctional() async throws {
        currentScenario = Scenario("Restored backup should be functional")
            .given("Cloud Agent is connected to Edge Agent")
            .and("Edge Agent has '1' jwt credentials issued by Cloud Agent")
            .and("Edge Agent creates '5' peer DIDs")
            .and("Edge Agent creates '3' prism DIDs")
            .and("Edge Agent has created a backup")
            .and("Restored Agent is created using Edge Agent seed")
            .then("a new Restored Agent is restored from Edge Agent")
            .and("Restored Agent should have the expected values from Edge Agent")
            .and("Edge Agent is dismissed")
            .given("Cloud Agent is connected to Restored Agent")
            .and("Cloud Agent asks for jwt present-proof")
            .when("Restored Agent sends the present-proof")
            .then("Cloud Agent should see the present-proof is verified")
    }
}
