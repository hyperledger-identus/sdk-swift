import Core
import Domain
import Foundation

public struct JWTEnvelopedVerifiableCredential<Credential: Codable>: RawCodable {
    public let iss: String?
    public let sub: String?
    public let nbf: Date?
    public let exp: Date?
    public let iat: Date?
    public let jti: String?
    public let aud: [String]?
    public let vc: Credential
    public let raw: AnyCodable?

    init(
        iss: String? = nil,
        sub: String? = nil,
        nbf: Date? = nil,
        exp: Date? = nil,
        iat: Date? = nil,
        jti: String? = nil,
        aud: [String]? = nil,
        vc: Credential,
        raw: AnyCodable? = nil
    ) {
        self.iss = iss
        self.sub = sub
        self.nbf = nbf
        self.exp = exp
        self.iat = iat
        self.jti = jti
        self.aud = aud
        self.vc = vc
        self.raw = raw
    }

    enum CodingKeys: CodingKey {
        case iss
        case sub
        case nbf
        case exp
        case iat
        case jti
        case aud
        case vc
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        iss = try container.decodeIfPresent(String.self, forKey: .iss)
        sub = try container.decodeIfPresent(String.self, forKey: .sub)
        nbf = try container.decodeIfPresent(Date.self, forKey: .nbf)
        exp = try container.decodeIfPresent(Date.self, forKey: .exp)
        iat = try container.decodeIfPresent(Date.self, forKey: .iat)
        jti = try container.decodeIfPresent(String.self, forKey: .jti)
        if let aud = try? container.decodeIfPresent([String].self, forKey: .aud) {
            self.aud = aud
        } else if let aud = try? container.decodeIfPresent(String.self, forKey: .aud) {
            self.aud = [aud]
        } else {
            aud = nil
        }
        
        if let vc = try container.decodeIfPresent(Credential.self, forKey: .vc) {
            self.vc = vc
        } else {
            self.vc = try Credential(from: decoder)
        }
        self.raw = try AnyCodable(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        guard let raw else {
            var container = encoder.container(keyedBy: JWTEnvelopedVerifiableCredential<Credential>.CodingKeys.self)
            try container.encodeIfPresent(self.iss, forKey: .iss)
            try container.encodeIfPresent(self.sub, forKey: .sub)
            try container.encodeIfPresent(self.nbf, forKey: .nbf)
            try container.encodeIfPresent(self.exp, forKey: .exp)
            try container.encodeIfPresent(self.iat, forKey: .iat)
            try container.encodeIfPresent(self.jti, forKey: .jti)
            try container.encodeIfPresent(self.aud, forKey: .aud)
            try container.encode(self.vc, forKey: .vc)
            return
        }
        try raw.encode(to: encoder)
    }
}
