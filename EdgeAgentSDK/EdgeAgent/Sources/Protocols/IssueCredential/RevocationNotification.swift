import Core
import Domain
import Foundation

// ALL parameters are DIDCOMMV2 format and naming conventions and follows the protocol
// https://github.com/hyperledger/aries-rfcs/blob/main/features/0183-revocation-notification/README.md
public struct RevocationNotification {
    public struct Body: Codable, Equatable {
        public let issueCredentialProtocolThreadId: String
        public let comment: String?

        public init(
            issueCredentialProtocolThreadId: String,
            comment: String? = nil
        ) {
            self.issueCredentialProtocolThreadId = issueCredentialProtocolThreadId
            self.comment = comment
        }
    }

    public let id: String
    public let type: String
    public let body: Body
    public let attachments: [AttachmentDescriptor]
    public let thid: String?
    public let from: DID
    public let to: DID

    init(
        id: String = UUID().uuidString,
        body: Body,
        type: String,
        attachments: [AttachmentDescriptor],
        thid: String?,
        from: DID,
        to: DID
    ) {
        self.id = id
        self.body = body
        self.type = type
        self.attachments = attachments
        self.thid = thid
        self.from = from
        self.to = to
    }

    public init(fromMessage: Message) throws {
        guard
            let piuri = ProtocolTypes(rawValue: fromMessage.piuri),
            piuri == ProtocolTypes.didcommRevocationNotification,
            let fromDID = fromMessage.from,
            let toDID = fromMessage.to
        else { throw EdgeAgentError.invalidMessageType(
            type: fromMessage.piuri,
            shouldBe: [ProtocolTypes.didcommRevocationNotification.rawValue]
        ) }

        let body = try JSONDecoder.didComm().decode(Body.self, from: fromMessage.body)
        self.init(
            id: fromMessage.id,
            body: body,
            type: piuri.rawValue,
            attachments: fromMessage.attachments,
            thid: fromMessage.thid,
            from: fromDID,
            to: toDID
        )
    }

    public func makeMessage() throws -> Message {
        .init(
            id: id,
            piuri: type,
            from: from,
            to: to,
            body: try JSONEncoder.didComm().encode(body),
            attachments: attachments,
            thid: thid,
            direction: .sent
        )
    }

    public static func makeRequestFromOfferCredential(offer: OfferCredential) throws -> RequestCredential {
        guard
            let offerPiuri = ProtocolTypes(rawValue: offer.type)
        else {
            throw EdgeAgentError.invalidMessageType(
                type: offer.type,
                shouldBe: [
                    ProtocolTypes.didcommRevocationNotification.rawValue
                ]
            )
        }

        return RequestCredential(
            body: .init(
                goalCode: offer.body?.goalCode,
                comment: offer.body?.comment,
                formats: offer.body?.formats ?? []
            ),
            type: ProtocolTypes.didcommRevocationNotification.rawValue,
            attachments: offer.attachments,
            thid: offer.thid, // TODO: This needs to be changed in the pr
            from: offer.to,
            to: offer.from
        )
    }
}

extension RevocationNotification: Equatable {
    public static func == (lhs: RevocationNotification, rhs: RevocationNotification) -> Bool {
        lhs.id == rhs.id &&
        lhs.type == rhs.type &&
        lhs.from == rhs.from &&
        lhs.to == rhs.to &&
        lhs.body == rhs.body
    }
}
