import Core
import Domain
import Foundation

// ALL parameters are DIDCOMMV2 format and naming conventions and follows the protocol
// https://github.com/hyperledger/aries-rfcs/tree/main/features/0453-issue-credential-v2
public struct RequestCredential {
    public struct Body: Codable, Equatable {
        public let goalCode: String?
        public let comment: String?
        public let formats: [CredentialFormat]

        public init(
            goalCode: String? = nil,
            comment: String? = nil,
            formats: [CredentialFormat]
        ) {
            self.goalCode = goalCode
            self.comment = comment
            self.formats = formats
        }
    }

    public let id: String
    public let type: String
    public let body: Body?
    public let attachments: [AttachmentDescriptor]
    public let thid: String?
    public let from: DID
    public let to: DID

    init(
        id: String = UUID().uuidString,
        body: Body?,
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
            (piuri == ProtocolTypes.didcommRequestCredential ||
             piuri == ProtocolTypes.didcommRequestCredential3_0),
            let fromDID = fromMessage.from,
            let toDID = fromMessage.to
        else { throw EdgeAgentError.invalidMessageType(
            type: fromMessage.piuri,
            shouldBe: [ProtocolTypes.didcommRequestCredential.rawValue]
        ) }

        let body = try? JSONDecoder.didComm().decode(Body.self, from: fromMessage.body)
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
                    ProtocolTypes.didcommOfferCredential.rawValue,
                    ProtocolTypes.didcommOfferCredential3_0.rawValue
                ]
            )
        }
        
        let type = offerPiuri == .didcommOfferCredential ?
            ProtocolTypes.didcommRequestCredential :
            ProtocolTypes.didcommRequestCredential3_0
        
        return RequestCredential(
            body: .init(
                goalCode: offer.body?.goalCode,
                comment: offer.body?.comment,
                formats: offer.body?.formats ?? []
            ),
            type: type.rawValue,
            attachments: offer.attachments,
            thid: offer.thid, // TODO: This needs to be changed in the pr
            from: offer.to,
            to: offer.from
        )
    }
}

extension RequestCredential: Equatable {
    public static func == (lhs: RequestCredential, rhs: RequestCredential) -> Bool {
        lhs.id == rhs.id &&
        lhs.type == rhs.type &&
        lhs.from == rhs.from &&
        lhs.to == rhs.to &&
        lhs.body == rhs.body
    }
}

// ALL parameters are DIDCOMMV2 format and naming conventions and follows the protocol
// https://github.com/hyperledger/aries-rfcs/tree/main/features/0453-issue-credential-v2
public struct RequestCredential3_0 {
    public struct Body: Codable, Equatable {
        public let goalCode: String?
        public let comment: String?

        public init(
            goalCode: String? = nil,
            comment: String? = nil
        ) {
            self.goalCode = goalCode
            self.comment = comment
        }
    }

    public let id: String
    public let type: String
    public let body: Body?
    public let attachments: [AttachmentDescriptor]
    public let thid: String?
    public let from: DID
    public let to: DID

    init(
        id: String = UUID().uuidString,
        body: Body?,
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
             piuri == ProtocolTypes.didcommRequestCredential3_0,
            let fromDID = fromMessage.from,
            let toDID = fromMessage.to
        else { throw EdgeAgentError.invalidMessageType(
            type: fromMessage.piuri,
            shouldBe: [ProtocolTypes.didcommRequestCredential3_0.rawValue]
        ) }

        let body = try? JSONDecoder.didComm().decode(Body.self, from: fromMessage.body)
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

    public static func makeRequestFromOfferCredential(offer: OfferCredential3_0) throws -> RequestCredential3_0 {
        guard
            let offerPiuri = ProtocolTypes(rawValue: offer.type),
            offerPiuri == ProtocolTypes.didcommOfferCredential3_0
        else {
            throw EdgeAgentError.invalidMessageType(
                type: offer.type,
                shouldBe: [
                    ProtocolTypes.didcommOfferCredential3_0.rawValue
                ]
            )
        }
        
        let type = ProtocolTypes.didcommRequestCredential3_0
        
        return RequestCredential3_0(
            body: .init(
                goalCode: offer.body?.goalCode,
                comment: offer.body?.comment
            ),
            type: type.rawValue,
            attachments: offer.attachments,
            thid: offer.thid,
            from: offer.to,
            to: offer.from
        )
    }
}

extension RequestCredential3_0: Equatable {
    public static func == (lhs: RequestCredential3_0, rhs: RequestCredential3_0) -> Bool {
        lhs.id == rhs.id &&
        lhs.type == rhs.type &&
        lhs.from == rhs.from &&
        lhs.to == rhs.to &&
        lhs.body == rhs.body
    }
}
