import Core
import Domain
import Foundation

// ALL parameterS are DIDCOMMV2 format and naming conventions and follows the protocol
// https://github.com/hyperledger/aries-rfcs/tree/main/features/0453-issue-credential-v2
public struct ProposeCredential {
    public struct Body: Codable, Equatable {
        public let goalCode: String?
        public let comment: String?
        public let credentialPreview: CredentialPreview
        public let formats: [CredentialFormat]

        public init(
            goalCode: String? = nil,
            comment: String? = nil,
            credentialPreview: CredentialPreview,
            formats: [CredentialFormat]
        ) {
            self.goalCode = goalCode
            self.comment = comment
            self.credentialPreview = credentialPreview
            self.formats = formats
        }
    }

    public let id: String
    public let type = ProtocolTypes.didcommProposeCredential.rawValue
    public let body: Body?
    public let attachments: [AttachmentDescriptor]
    public let thid: String?
    public let from: DID
    public let to: DID

    init(
        id: String = UUID().uuidString,
        body: Body?,
        attachments: [AttachmentDescriptor],
        thid: String?,
        from: DID,
        to: DID
    ) {
        self.id = id
        self.body = body
        self.attachments = attachments
        self.thid = thid
        self.from = from
        self.to = to
    }

    public init(fromMessage: Message) throws {
        guard
            fromMessage.piuri == ProtocolTypes.didcommProposeCredential.rawValue,
            let fromDID = fromMessage.from,
            let toDID = fromMessage.to
        else { throw EdgeAgentError.invalidMessageType(
            type: fromMessage.piuri,
            shouldBe: [ProtocolTypes.didcommProposeCredential.rawValue]
        ) }
        let body = try? JSONDecoder.didComm().decode(Body.self, from: fromMessage.body)
        self.init(
            id: fromMessage.id,
            body: body,
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

    static func build<T: Encodable>(
        fromDID: DID,
        toDID: DID,
        thid: String?,
        credentialPreview: CredentialPreview,
        credentials: [String: T] = [:]
    ) throws -> ProposeCredential {
        let aux = try credentials.map { key, value in
            let attachment = try AttachmentDescriptor.build(payload: value)
            let format = CredentialFormat(attachId: attachment.id, format: key)
            return (format, attachment)
        }
        return ProposeCredential(
            body: Body(
                credentialPreview: credentialPreview,
                formats: aux.map { $0.0 }
            ),
            attachments: aux.map { $0.1 },
            thid: thid,
            from: fromDID,
            to: toDID
        )
    }
}

extension ProposeCredential: Equatable {
    public static func == (lhs: ProposeCredential, rhs: ProposeCredential) -> Bool {
        lhs.id == rhs.id &&
        lhs.type == rhs.type &&
        lhs.from == rhs.from &&
        lhs.to == rhs.to &&
        lhs.body == rhs.body
    }
}

// ALL parameterS are DIDCOMMV2 format and naming conventions and follows the protocol
// https://github.com/hyperledger/aries-rfcs/tree/main/features/0453-issue-credential-v2
public struct ProposeCredential3_0 {
    public struct Body: Codable, Equatable {
        public let goalCode: String?
        public let comment: String?
        public let credentialPreview: CredentialPreview3_0?

        public init(
            goalCode: String? = nil,
            comment: String? = nil,
            credentialPreview: CredentialPreview3_0?
        ) {
            self.goalCode = goalCode
            self.comment = comment
            self.credentialPreview = credentialPreview
        }
    }

    public let id: String
    public let type = ProtocolTypes.didcommProposeCredential3_0.rawValue
    public let body: Body?
    public let attachments: [AttachmentDescriptor]
    public let thid: String?
    public let from: DID
    public let to: DID

    init(
        id: String = UUID().uuidString,
        body: Body?,
        attachments: [AttachmentDescriptor],
        thid: String?,
        from: DID,
        to: DID
    ) {
        self.id = id
        self.body = body
        self.attachments = attachments
        self.thid = thid
        self.from = from
        self.to = to
    }

    public init(fromMessage: Message) throws {
        guard
            fromMessage.piuri == ProtocolTypes.didcommProposeCredential3_0.rawValue,
            let fromDID = fromMessage.from,
            let toDID = fromMessage.to
        else { throw EdgeAgentError.invalidMessageType(
            type: fromMessage.piuri,
            shouldBe: [ProtocolTypes.didcommProposeCredential3_0.rawValue]
        ) }
        let body = try? JSONDecoder.didComm().decode(Body.self, from: fromMessage.body)
        self.init(
            id: fromMessage.id,
            body: body,
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
}

extension ProposeCredential3_0: Equatable {
    public static func == (lhs: ProposeCredential3_0, rhs: ProposeCredential3_0) -> Bool {
        lhs.id == rhs.id &&
        lhs.type == rhs.type &&
        lhs.from == rhs.from &&
        lhs.to == rhs.to &&
        lhs.body == rhs.body
    }
}
