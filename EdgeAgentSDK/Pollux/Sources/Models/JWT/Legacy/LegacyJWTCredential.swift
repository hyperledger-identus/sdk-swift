import Domain
import Foundation
import JSONWebSignature

public struct LegacyJWTCredential {
    let jwtString: String
    let jwtVerifiableCredential: JWTPayload

    public init(jwtString: String) throws {
        var jwtParts = jwtString.components(separatedBy: ".")
        guard jwtParts.count == 3 else { throw PolluxError.invalidJWTString }
        jwtParts.removeFirst()
        guard
            let credentialString = jwtParts.first,
            let base64Data = Data(fromBase64URL: credentialString),
            let jsonString = String(data: base64Data, encoding: .utf8)
        else { throw PolluxError.invalidJWTString }

        guard let dataValue = jsonString.data(using: .utf8) else { throw PolluxError.invalidCredentialError }
        self.jwtString = jwtString
        self.jwtVerifiableCredential = try JSONDecoder().decode(JWTPayload.self, from: dataValue)
    }

    public init(data: Data) throws {
        guard let jwtString = String(data: data, encoding: .utf8) else { throw PolluxError.invalidJWTString }
        try self.init(jwtString: jwtString)
    }
}

extension LegacyJWTCredential: Codable {}

extension LegacyJWTCredential: Credential {
    public var id: String {
        jwtString
    }
    
    public var issuer: String {
        jwtVerifiableCredential.iss.string
    }
    
    public var subject: String? {
        jwtVerifiableCredential.sub
    }
    
    public var claims: [Claim] {
        guard
            let dic = jwtVerifiableCredential.verifiableCredential.credentialSubject.value as? [String: Any]
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
            "nbf" : jwtVerifiableCredential.nbf,
            "jti" : jwtVerifiableCredential.jti,
            "type" : jwtVerifiableCredential.verifiableCredential.type,
            "aud" : jwtVerifiableCredential.aud,
            "id" : jwtString
        ] as [String : Any]
        
        jwtVerifiableCredential.exp.map { properties["exp"] = $0 }
        jwtVerifiableCredential.verifiableCredential.credentialSchema.map { properties["schema"] = $0.id }
        jwtVerifiableCredential.verifiableCredential.credentialStatus.map { properties["credentialStatus"] = $0.type }
        jwtVerifiableCredential.verifiableCredential.refreshService.map { properties["refreshService"] = $0.type }
        jwtVerifiableCredential.verifiableCredential.evidence.map { properties["evidence"] = $0.type }
        jwtVerifiableCredential.verifiableCredential.termsOfUse.map { properties["termsOfUse"] = $0.type }
        
        return properties
    }
    
    public var credentialType: String { "JWT" }
}

extension LegacyJWTCredential {
    func getJSON() throws -> Data {
        var jwtParts = jwtString.components(separatedBy: ".")
        jwtParts.removeFirst()
        guard
            let credentialString = jwtParts.first,
            let base64Data = Data(fromBase64URL: credentialString),
            let jsonString = String(data: base64Data, encoding: .utf8)
        else { throw PolluxError.invalidJWTString }

        guard let dataValue = jsonString.data(using: .utf8) else { throw PolluxError.invalidCredentialError }
        return dataValue
    }

    func getAlg() throws -> String {
        let jwtParts = jwtString.components(separatedBy: ".")
        guard
            let headerString = jwtParts.first,
            let base64Data = Data(fromBase64URL: headerString),
            let alg = try JSONDecoder.didComm().decode(DefaultJWSHeaderImpl.self, from: base64Data).algorithm?.rawValue
        else { throw PolluxError.couldNotFindCredentialAlgorithm }

        return alg
    }
}
