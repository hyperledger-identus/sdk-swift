import Domain
import Foundation

public struct JWTEnvelopedVerifiableCredential<Credential: Codable>: Codable {
    public let iss: String?
    public let sub: String?
    public let nbf: Date?
    public let exp: Date?
    public let iat: Date?
    public let jti: String?
    public let aud: [String]?
    public let vc: Credential

    init(
        iss: String? = nil,
        sub: String? = nil,
        nbf: Date? = nil,
        exp: Date? = nil,
        iat: Date? = nil,
        jti: String? = nil,
        aud: [String]? = nil,
        vc: Credential
    ) {
        self.iss = iss
        self.sub = sub
        self.nbf = nbf
        self.exp = exp
        self.iat = iat
        self.jti = jti
        self.aud = aud
        self.vc = vc
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
    }
}
