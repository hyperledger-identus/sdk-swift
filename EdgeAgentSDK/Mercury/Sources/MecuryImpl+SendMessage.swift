import Domain
import Foundation

extension MercuryImpl {
    /// sendMessage asynchronously sends a given message and returns the response data. This function may throw an error if the message is invalid or the send operation fails.
    ///
    /// - Parameter msg: The message to send
    /// - Returns: The response data
    /// - Throws: An error if the message is invalid or the send operation fails
    public func sendMessage(_ msg: Message) async throws -> Data? {
        guard let toDID = msg.to else { throw MercuryError.noRecipientDIDSetError }
        guard let fromDID = msg.from else { throw MercuryError.noRecipientDIDSetError }
        let document = try await castor.resolveDID(did: toDID)

        let originalPackedMessage = try await packMessage(msg: msg)
        if
            requiresForwarding(document: document),
            let mediatorDID = getDIDCommDID(document: document),
            let encryptedData = originalPackedMessage.data(using: .utf8)
        {
            let forwardMessage = try prepareForwardMessage(
                msg: msg,
                encrypted: encryptedData,
                mediatorDID: mediatorDID
            )

            logger.debug(
                message: "Sending forward message with internal message type \(msg.piuri)",
                metadata: [
                    .maskedMetadataByLevel(
                        key: "Sender",
                        value: forwardMessage.from.string,
                        level: .debug
                    ),
                    .maskedMetadataByLevel(
                        key: "Receiver",
                        value: forwardMessage.to.string,
                        level: .debug
                    )
                ]
            )
            let forwardPackedMessage = try await packMessage(msg: forwardMessage.makeMessage())
            let mediatorDocument = try await castor.resolveDID(did: mediatorDID)
            guard
                let url = getDIDCommURL(document: mediatorDocument),
                let data = forwardPackedMessage.data(using: .utf8)
            else {
                throw MercuryError.noValidServiceFoundError(did: mediatorDID.string)
            }
            return try await sendHTTPMessage(url: url, packedMessage: data)
        } else {
            guard
                let url = getDIDCommURL(document: document),
                let data = originalPackedMessage.data(using: .utf8)
            else {
                throw MercuryError.noValidServiceFoundError(did: toDID.string)
            }
            logger.debug(
                message: "Sending message with type \(msg.piuri)",
                metadata: [
                    .maskedMetadataByLevel(
                        key: "Sender",
                        value: fromDID.string,
                        level: .debug
                    ),
                    .maskedMetadataByLevel(
                        key: "Receiver",
                        value: toDID.string,
                        level: .debug
                    )
                ]
            )
            return try await sendHTTPMessage(url: url, packedMessage: data)
        }
    }

    /// sendMessageParseMessage asynchronously sends a given message and returns the response message object. This function may throw an error if the message is invalid, the send operation fails, or the response message is invalid.
    ///
    /// - Parameter msg: The message to send
    /// - Returns: The response message object
    /// - Throws: An error if the message is invalid, the send operation fails, or the response message is invalid
    public func sendMessageParseMessage(msg: Message) async throws -> Message? {
        guard
            let msgData = try await sendMessage(msg),
            let msgStr = String(data: msgData, encoding: .utf8),
            msgStr != "null",
            !msgStr.isEmpty
        else { return nil }
        return try? await self.unpackMessage(msg: msgStr)
    }

    private func sendHTTPMessage(url: URL, packedMessage: Data) async throws -> Data? {
        return try await session.post(
            url: url,
            body: packedMessage,
            headers: ["content-type": MediaType.contentTypeEncrypted.rawValue]
        )
    }
    private func prepareForwardMessage(
        msg: Message,
        encrypted: Data,
        mediatorDID: DID
    ) throws -> ForwardMessage {
        guard let fromDID = msg.from else { throw MercuryError.noSenderDIDSetError }
        guard let toDID = msg.to else { throw MercuryError.noRecipientDIDSetError }
        return ForwardMessage(
            from: fromDID,
            to: mediatorDID,
            body: .init(next: toDID.string),
            encryptedJsonMessage: encrypted
        )
    }

    private func getDIDCommURL(document: DIDDocument) -> URL? {
        document.services
            .first { $0.type.array.contains("DIDCommMessaging") }
            .map {
                $0.serviceEndpoint
                    .array
                    .map { URL(string: $0.uri) }
                    .compactMap { $0 }
            }?.first
    }

    private func getDIDCommDID(document: DIDDocument) -> DID? {
        document.services
            .first { $0.type.array.contains("DIDCommMessaging") }
            .map {
                $0.serviceEndpoint
                    .array
                    .map { try? castor.parseDID(str: $0.uri) }
                    .compactMap { $0 }
            }?.first
    }

    private func requiresForwarding(document: DIDDocument) -> Bool {
        if getDIDCommDID(document: document) != nil {
            return true
        } else {
            return false
        }
    }
}
