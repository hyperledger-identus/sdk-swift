import Domain
import Foundation
import eudi_lib_sdjwt_swift
import JSONWebSignature

struct SDJWTCredential {
    let sdjwtString: String
    let sdjwt: SignedSDJWT

    init(sdjwtString: String) throws {
        let sdjwt = try CompactParser().getSignedSdJwt(serialisedString: sdjwtString)
        self.sdjwtString = sdjwtString
        self.sdjwt = sdjwt
    }
}

fileprivate struct SDJWTComplex: Codable {
    let disclosures: [String]
}

extension SDJWTCredential: Credential {
    var id: String {
        sdjwtString
    }
    
    var issuer: String {
        (try? sdjwt.recreateClaims().recreatedClaims["iss"].stringValue) ?? ""
    }
    
    var subject: String? {
        (try? sdjwt.recreateClaims().recreatedClaims["sub"].stringValue) ?? ""
    }
    
    var claims: [Domain.Claim] {
        sdjwt.disclosures.compactMap {
            guard
                let base64Decoded = Data(fromBase64URL: $0),
                let array = try? JSONDecoder().decode([String].self, from: base64Decoded),
                array.count == 3
            else {
                return nil
            }
            let key = array[1]
            let value = array[2]
            return Claim(key: key, value: .string(value))
        }
    }
    
    var properties: [String : Any] {
        return [:]
    }
    
    var credentialType: String {
        return "sd-jwt"
    }
}

extension SDJWTCredential {
    func getAlg() throws -> String? {
        return sdjwt.jwt.protectedHeader.algorithm?.rawValue
    }
}
