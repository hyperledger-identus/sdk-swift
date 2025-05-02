import Core
import Domain
import Foundation

// ALL parameters are DIDCOMMV2 format and naming conventions and follows the protocol
// https://github.com/hyperledger/aries-rfcs/tree/main/features/0453-issue-credential-v2
public struct OfferCredential {
    public struct Body: Codable, Equatable {
        public let goalCode: String?
        public let comment: String?
        public let replacementId: String?
        public let multipleAvailable: String?
        public let credentialPreview: CredentialPreview
        public let formats: [CredentialFormat]

        public init(
            goalCode: String? = nil,
            comment: String? = nil,
            replacementId: String? = nil,
            multipleAvailable: String? = nil,
            credentialPreview: CredentialPreview,
            formats: [CredentialFormat]
        ) {
            self.goalCode = goalCode
            self.comment = comment
            self.replacementId = replacementId
            self.multipleAvailable = multipleAvailable
            self.credentialPreview = credentialPreview
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

    public init(
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
            piuri == ProtocolTypes.didcommOfferCredential,
            let fromDID = fromMessage.from,
            let toDID = fromMessage.to
        else { throw EdgeAgentError.invalidMessageType(
            type: fromMessage.piuri,
            shouldBe: [ProtocolTypes.didcommOfferCredential.rawValue]
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

    public static func makeOfferFromProposedCredential(proposed: ProposeCredential) throws -> OfferCredential {
        guard
            let proposePiuri = ProtocolTypes(rawValue: proposed.type)
        else {
            throw EdgeAgentError.invalidMessageType(
                type: proposed.type,
                shouldBe: [
                    ProtocolTypes.didcommProposeCredential.rawValue
                ]
            )
        }
        
        let type = ProtocolTypes.didcommOfferCredential
        
        return OfferCredential(
            body: Body(
                goalCode: proposed.body?.goalCode,
                comment: proposed.body?.comment,
                credentialPreview: proposed.body?.credentialPreview ?? .init(attributes: []),
                formats: proposed.body?.formats ?? []
            ),
            type: type.rawValue,
            attachments: proposed.attachments,
            thid: proposed.id,
            from: proposed.to,
            to: proposed.from)
    }
}

extension OfferCredential: Equatable {
    public static func == (lhs: OfferCredential, rhs: OfferCredential) -> Bool {
        lhs.id == rhs.id &&
        lhs.type == rhs.type &&
        lhs.from == rhs.from &&
        lhs.to == rhs.to &&
        lhs.body == rhs.body
    }
}

// ALL parameters are DIDCOMMV2 format and naming conventions and follows the protocol
// https://github.com/hyperledger/aries-rfcs/tree/main/features/0453-issue-credential-v2
public struct OfferCredential3_0 {
    public struct Body: Codable, Equatable {
        public let goalCode: String?
        public let comment: String?
        public let replacementId: String?
        public let multipleAvailable: String?
        public let credentialPreview: CredentialPreview3_0?

        public init(
            goalCode: String? = nil,
            comment: String? = nil,
            replacementId: String? = nil,
            multipleAvailable: String? = nil,
            credentialPreview: CredentialPreview3_0?
        ) {
            self.goalCode = goalCode
            self.comment = comment
            self.replacementId = replacementId
            self.multipleAvailable = multipleAvailable
            self.credentialPreview = credentialPreview
        }
    }

    public let id: String
    public let type: String
    public let body: Body?
    public let attachments: [AttachmentDescriptor]
    public let thid: String?
    public let from: DID
    public let to: DID

    public init(
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

    public init(fromMessage: Message, toDID: DID? = nil) throws {
        guard
            let piuri = ProtocolTypes(rawValue: fromMessage.piuri),
             piuri == ProtocolTypes.didcommOfferCredential3_0,
            let fromDID = fromMessage.from,
            let toDID = fromMessage.to ?? toDID
        else { throw EdgeAgentError.invalidMessageType(
            type: fromMessage.piuri,
            shouldBe: [ProtocolTypes.didcommOfferCredential.rawValue]
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

    public static func makeOfferFromProposedCredential(proposed: ProposeCredential3_0) throws -> OfferCredential3_0 {
        guard
            let proposePiuri = ProtocolTypes(rawValue: proposed.type)
        else {
            throw EdgeAgentError.invalidMessageType(
                type: proposed.type,
                shouldBe: [
                    ProtocolTypes.didcommProposeCredential3_0.rawValue
                ]
            )
        }
        
        let type = proposePiuri == .didcommProposeCredential ?
            ProtocolTypes.didcommOfferCredential :
            ProtocolTypes.didcommOfferCredential3_0
        
        return OfferCredential3_0(
            body: Body(
                goalCode: proposed.body?.goalCode,
                comment: proposed.body?.comment,
                credentialPreview: proposed.body?.credentialPreview
            ),
            type: type.rawValue,
            attachments: proposed.attachments,
            thid: proposed.id,
            from: proposed.to,
            to: proposed.from)
    }
}

extension OfferCredential3_0: Equatable {
    public static func == (lhs: OfferCredential3_0, rhs: OfferCredential3_0) -> Bool {
        lhs.id == rhs.id &&
        lhs.type == rhs.type &&
        lhs.from == rhs.from &&
        lhs.to == rhs.to &&
        lhs.body == rhs.body
    }
}
