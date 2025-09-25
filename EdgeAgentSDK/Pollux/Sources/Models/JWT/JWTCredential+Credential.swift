import Domain
import Foundation

extension JWTCredential: Credential {

    public var id: String {
        defaultEnvelop.vc.id ?? defaultEnvelop.jti ?? jwtString
    }

    public var issuer: String {
        defaultEnvelop.iss ?? defaultEnvelop.vc.issuer.id
    }

    public var subject: String? {
        defaultEnvelop.sub ?? defaultEnvelop.vc.credentialSubject.array.compactMap(\.id).first
    }

    public var claims: [Domain.Claim] {
        guard
            let dic = defaultEnvelop.vc.credentialSubject.array.first?.raw?.value as? [String: Any]
        else {
            return []
        }
        return dic.compactMap {
            switch $1 {
            case let value as Date:
                Claim(key: $0, value: .date(value))
            case let value as Data:
                Claim(key: $0, value: .data(value))
            case let value as Bool:
                Claim(key: $0, value: .bool(value))
            case let value as String:
                Claim(key: $0, value: .string(value))
            case let value as NSNumber:
                Claim(key: $0, value: .number(value.doubleValue))
            default:
                nil
            }
        }
    }

    public var properties: [String : Any] {
        var properties = [
            "nbf" : defaultEnvelop.nbf as Any,
            "jti" : defaultEnvelop.jti as Any,
            "type" : defaultEnvelop.vc.type,
            "aud" : defaultEnvelop.aud as Any
        ] as [String : Any]

        defaultEnvelop.exp.map { properties["exp"] = $0 }
        defaultEnvelop.vc.credentialSchema?.array.first.map { properties["schema"] = $0.id }
        defaultEnvelop.vc.credentialStatus.map { properties["credentialStatus"] = $0.type }

        return properties
    }

    public var credentialType: String {
        "vc+jwt"
    }
}
