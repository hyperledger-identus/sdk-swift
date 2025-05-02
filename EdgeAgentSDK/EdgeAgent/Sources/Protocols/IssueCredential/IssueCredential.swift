import Core
import Domain
import Foundation

// ALL parameters are DIDCOMMV2 format and naming conventions and follows the protocol
// https://github.com/hyperledger/aries-rfcs/tree/main/features/0453-issue-credential-v2
public struct IssueCredential {
    public struct Body: Codable, Equatable {
        public let goalCode: String?
        public let comment: String?
        public let replacementId: String?
        public let moreAvailable: String?
        public let formats: [CredentialFormat]

        init(
            goalCode: String? = nil,
            comment: String? = nil,
            replacementId: String? = nil,
            moreAvailable: String? = nil,
            formats: [CredentialFormat]
        ) {
            self.goalCode = goalCode
            self.comment = comment
            self.replacementId = replacementId
            self.moreAvailable = moreAvailable
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
            (piuri == ProtocolTypes.didcommIssueCredential ||
             piuri == ProtocolTypes.didcommIssueCredential3_0),
            let fromDID = fromMessage.from,
            let toDID = fromMessage.to
        else { throw EdgeAgentError.invalidMessageType(
            type: fromMessage.piuri,
            shouldBe: [ProtocolTypes.didcommIssueCredential.rawValue]
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

    public static func makeIssueFromRequestCredential(msg: Message) throws -> IssueCredential {
        let request = try RequestCredential(fromMessage: msg)
        
        guard
            let requestPiuri = ProtocolTypes(rawValue: request.type)
        else {
            throw EdgeAgentError.invalidMessageType(
                type: request.type,
                shouldBe: [
                    ProtocolTypes.didcommRequestCredential.rawValue,
                    ProtocolTypes.didcommRequestCredential3_0.rawValue
                ]
            )
        }
        
        let type = requestPiuri == .didcommRequestCredential ?
            ProtocolTypes.didcommIssueCredential :
            ProtocolTypes.didcommIssueCredential3_0
        
        return IssueCredential(
            body: Body(
                goalCode: request.body?.goalCode,
                comment: request.body?.comment,
                formats: request.body?.formats ?? []
            ),
            type: type.rawValue,
            attachments: request.attachments,
            thid: msg.id,
            from: request.to,
            to: request.from)
    }

    func getCredentialStrings() throws -> [String] {
        attachments.compactMap {
            switch $0.data {
            case let data as AttachmentBase64:
                guard
                    let base64 = Data(base64URLEncoded: data.base64),
                    let str = String(data: base64, encoding: .utf8)
                else { return nil }
                return str
            default:
                return nil
            }
        }
    }
}

extension IssueCredential: Equatable {
    public static func == (lhs: IssueCredential, rhs: IssueCredential) -> Bool {
        lhs.id == rhs.id &&
        lhs.type == rhs.type &&
        lhs.from == rhs.from &&
        lhs.to == rhs.to &&
        lhs.body == rhs.body
    }
}

// ALL parameters are DIDCOMMV2 format and naming conventions and follows the protocol
// https://github.com/hyperledger/aries-rfcs/tree/main/features/0453-issue-credential-v2
public struct IssueCredential3_0 {
    public struct Body: Codable, Equatable {
        public let goalCode: String?
        public let comment: String?
        public let replacementId: String?

        init(
            goalCode: String? = nil,
            comment: String? = nil,
            replacementId: String? = nil
        ) {
            self.goalCode = goalCode
            self.comment = comment
            self.replacementId = replacementId
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
             piuri == ProtocolTypes.didcommIssueCredential3_0,
            let fromDID = fromMessage.from,
            let toDID = fromMessage.to
        else { throw EdgeAgentError.invalidMessageType(
            type: fromMessage.piuri,
            shouldBe: [ProtocolTypes.didcommIssueCredential3_0.rawValue]
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

    public static func makeIssueFromRequestCredential(msg: Message) throws -> IssueCredential3_0 {
        let request = try RequestCredential3_0(fromMessage: msg)
        
        guard
            let requestPiuri = ProtocolTypes(rawValue: request.type)
        else {
            throw EdgeAgentError.invalidMessageType(
                type: request.type,
                shouldBe: [
                    ProtocolTypes.didcommRequestCredential3_0.rawValue
                ]
            )
        }
        
        let type = ProtocolTypes.didcommIssueCredential3_0
        
        return IssueCredential3_0(
            body: Body(
                goalCode: request.body?.goalCode,
                comment: request.body?.comment
            ),
            type: type.rawValue,
            attachments: request.attachments,
            thid: msg.id,
            from: request.to,
            to: request.from)
    }

    func getCredentialStrings() throws -> [String] {
        attachments.compactMap {
            switch $0.data {
            case let data as AttachmentBase64:
                guard
                    let base64 = Data(base64URLEncoded: data.base64),
                    let str = String(data: base64, encoding: .utf8)
                else { return nil }
                return str
            default:
                return nil
            }
        }
    }
}

extension IssueCredential3_0: Equatable {
    public static func == (lhs: IssueCredential3_0, rhs: IssueCredential3_0) -> Bool {
        lhs.id == rhs.id &&
        lhs.type == rhs.type &&
        lhs.from == rhs.from &&
        lhs.to == rhs.to &&
        lhs.body == rhs.body
    }
}
