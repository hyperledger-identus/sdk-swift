import Core
import Foundation

extension Message: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case piuri
        case type
        case from
        case to
        case fromPrior
        case extraHeaders
        case createdTime
        case expiresTimePlus
        case attachments
        case thid
        case pthid
        case ack
        case body
        case direction
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(piuri, forKey: .type)
        if let dic = try? JSONSerialization.jsonObject(with: body) as? [String: Any?] {
            // Remove nil and NSNull values, producing a non-optional [String: Any]
            var filtered: [String: Any] = [:]
            for (key, value) in dic {
                if let unwrapped = value, !(unwrapped is NSNull) {
                    filtered[key] = unwrapped
                }
            }
            try container.encode(AnyCodable(value: filtered), forKey: .body)
        } else {
            try container.encode(body, forKey: .body)
        }
        try container.encodeIfPresent(extraHeaders, forKey: .extraHeaders)
        try container.encodeIfPresent(createdTime, forKey: .createdTime)
        try container.encodeIfPresent(expiresTimePlus, forKey: .expiresTimePlus)
        try container.encodeIfPresent(attachments, forKey: .attachments)
        try container.encodeIfPresent(ack, forKey: .ack)
        try from.map { try container.encode($0.string, forKey: .from) }
        try to.map { try container.encode($0.string, forKey: .to) }
        try fromPrior.map { try container.encode($0, forKey: .fromPrior) }
        try thid.map { try container.encode($0, forKey: .thid) }
        try pthid.map { try container.encode($0, forKey: .pthid) }
        try container.encode(direction, forKey: .direction)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let piuri: String
        if let type = try container.decodeIfPresent(String.self, forKey: .piuri) {
            piuri = type
        } else {
            piuri = try container.decode(String.self, forKey: .type)
        }
        let body: Data?
        if 
            let bodyCodable = try? container.decodeIfPresent(AnyCodable.self, forKey: .body),
            (bodyCodable.value is [String: Any] || bodyCodable.value is [String]),
            JSONSerialization.isValidJSONObject(bodyCodable.value),
            let bodyData = try? JSONSerialization.data(withJSONObject: bodyCodable.value)
        {
            body = bodyData
        } else if let bodyData = try? container.decodeIfPresent(Data.self, forKey: .body) {
            body = bodyData
        } else {
            body = nil
        }
        let extraHeaders = try container.decodeIfPresent([String: String].self, forKey: .extraHeaders)
        let createdTime = try container.decodeIfPresent(Date.self, forKey: .createdTime)
        let expiresTimePlus = try container.decodeIfPresent(Date.self, forKey: .expiresTimePlus)
        let attachments = try container.decodeIfPresent([AttachmentDescriptor].self, forKey: .attachments)
        let ack = try container.decodeIfPresent([String].self, forKey: .ack)
        let from = try? container.decodeIfPresent(String.self, forKey: .from)
        let to = try? container.decodeIfPresent(String.self, forKey: .to)
        let fromPrior = try? container.decodeIfPresent(String.self, forKey: .fromPrior)
        let thid = try? container.decodeIfPresent(String.self, forKey: .thid)
        let pthid = try? container.decodeIfPresent(String.self, forKey: .pthid)
        let direction = try? container.decodeIfPresent(Direction.self, forKey: .direction)

        self.init(
            id: id,
            piuri: piuri,
            from: try from.map { try DID(string: $0) },
            to: try to.map { try DID(string: $0) },
            fromPrior: fromPrior,
            body: body ?? Data(),
            extraHeaders: extraHeaders ?? [:],
            createdTime: createdTime ?? Date(),
            expiresTimePlus: expiresTimePlus,
            attachments: attachments ?? [],
            thid: thid,
            pthid: pthid,
            ack: ack ?? [],
            direction: direction ?? .received
        )
    }
}

