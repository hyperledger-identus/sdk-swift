import Combine
import Domain
import Foundation

public extension DIDCommAgent {
    /// Start fetching the messages from the mediator
    func startFetchingMessages(timeBetweenRequests: Int = 5) {
        let timeInterval = max(timeBetweenRequests, 5)
        guard
            let connectionManager,
            messagesStreamTask == nil
        else { return }

        logger.info(message: "Start streaming new unread messages")
        let manager = connectionManager
        messagesStreamTask = Task {
            // Keep trying to fetch messages until the task is cancelled
            while !Task.isCancelled {
                do {
                     logger.debug(message: "Fetching new batch of 10 unread messages")
                    // Wait for new messages to arrive
                     _ = try await manager.awaitMessages()
                } catch {
                    // Handle errors that occur during the message fetching process
                    logger.error(error: error)
                }
                sleep(UInt32(timeInterval))
            }
        }
    }

    /// Stop fetching messages
    func stopFetchingMessages() {
        logger.info(message: "Stop streaming new unread messages")
        messagesStreamTask?.cancel()
    }

    /// Handles the messages events and return a publisher of the messages
    /// - Returns: A publisher of the messages that emits an event with a `Message` and completed or failed with an `Error`
    func handleMessagesEvents() -> AnyPublisher<Message, Error> {
        pluto.getAllMessages()
            .flatMap { $0.publisher }
            .eraseToAnyPublisher()
    }

    /// Sends a DIDComm message through HTTP using mercury and returns a message if this is returned immediately by the REST endpoint.
    ///
    /// - Parameters:
    ///   - message: The message to be sent.
    /// - Returns: The sent message if successful, otherwise `nil`.
    /// - Throws: An error if the sending fails.
    func sendMessage(message: Message) async throws -> Message? {
        return try await connectionManager?.sendMessage(message)
    }

    /// Handles the received messages events and return a publisher of the messages
    /// - Returns: A publisher of the messages that emits an event with a `Message` and completed or failed with an `Error`
    func handleReceivedMessagesEvents() -> AnyPublisher<Message, Error> {
        pluto.getAllMessagesReceived()
            .flatMap { $0.publisher }
            .eraseToAnyPublisher()
    }
}
