import Domain
import Foundation
import eudi_lib_sdjwt_swift
import JSONWebKey
import JSONWebToken
import Core

struct VerifySDJWT {
    let castor: Castor
    let logger: SDKLogger

    func verifySDJWT(sdjwtString: String) async throws -> Bool {
        let issuer = try getIssuer(sdjwtString: sdjwtString)
        let issuerDID = try DID(string: issuer)
        let issuerKeys = try await castor
            .getDIDPublicKeys(did: issuerDID)
            .compactMap { $0.exporting }
            .compactMap { try $0.jwk.toJoseJWK() }

        return try verifyAllKeysSDJWT(sdjwtString: sdjwtString, keys: issuerKeys)
    }

    private func verifyAllKeysSDJWT(sdjwtString: String, keys: [JSONWebKey.JWK]) throws -> Bool {
        var isVerified = false
        keys.forEach { key in
            do {
                let result = try verifyForKeySDJWT(sdjwtString: sdjwtString, key: key)
                guard result else {
                    return
                }
                isVerified = true
            } catch {
                logger.warning(message: "A verification try with key \(key.keyID) failed with error \(error.localizedDescription)")
            }
        }
        return isVerified
    }

    private func verifyForKeySDJWT(sdjwtString: String, key: JSONWebKey.JWK) throws -> Bool {
        let result = try SDJWTVerifier(parser: CompactParser(serialisedString: sdjwtString))
            .verifyPresentation { jws in
                try SignatureVerifier(signedJWT: jws, publicKey: key)
            }
        switch result {
        case .success:
            return true
        case .failure(let failure):
            throw failure
        }
    }

    private func getIssuer(sdjwtString: String) throws -> String {
        guard
            let jwt = sdjwtString.components(separatedBy: "~").first,
            let issuer = try JWT.getIssuer(jwtString: jwt)
        else { throw PolluxError.invalidCredentialError }
        
        return issuer
    }
}
