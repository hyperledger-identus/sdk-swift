import TestFramework

final class MediatorMessagePickup: Feature {
    override var tags: [String] { ["mediator_pickup"] }
    override var title: String { "Mediator message pickup after wallet restore" }
    override var narrative: String {
        "When a wallet that was connected to a Mediator is destroyed and later recovered " +
        "from the same seed, it should retrieve any messages queued at the Mediator " +
        "while it was disconnected"
    }

    func testRestoredWalletPicksUpMessagesQueuedAtMediatorWhileDisconnected() async throws {
        currentScenario = Scenario("Restored wallet picks up messages queued at Mediator while disconnected")
            .given("Cloud Agent is connected to Edge Agent")
            .and("Edge Agent has created a backup")
            .when("Edge Agent is dismissed")
            .and("Cloud Agent offers '1' jwt credentials")
            .and("a new Restored Agent is restored from Edge Agent")
            .then("Restored Agent should receive the credentials offer from Cloud Agent")
    }
}
