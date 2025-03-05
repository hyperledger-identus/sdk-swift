import Combine
import Domain
import Foundation
import JSONWebAlgorithms
import JSONWebKey
import JSONWebToken
import JSONWebSignature

private struct Schema: Codable {
    let name: String
    let version: String
    let attrNames: [String]
    let issuerId: String
}

struct CreateSDJWTCredentialRequest {
    static func create(didStr: String, keys: [ExportableKey], offerData: Data) async throws -> String {
        let jsonObject = try JSONSerialization.jsonObject(with: offerData)
        guard
            let domain = findValue(forKey: "domain", in: jsonObject),
            let challenge = findValue(forKey: "challenge", in: jsonObject),
            let key = keys.filter({ $0.jwk.crv?.lowercased() == "ed25519" }).first
        else { throw PolluxError.offerDoesntProvideEnoughInformation }

        let keyJWK = key.jwk
        let claims = ClaimsRequestSignatureJWT(
            iss: didStr,
            sub: nil,
            aud: [domain],
            exp: nil,
            nbf: nil,
            iat: nil,
            jti: nil,
            nonce: challenge,
            vp: .init(context: .init([
                "https://www.w3.org/2018/presentations/v1"
            ]), type: .init([
                "VerifiablePresentation"
            ]))
        )

        guard let kty = JWK.KeyType(rawValue: keyJWK.kty) else { throw PolluxError.invalidPrismDID }
        let jwt = try JWT.signed(
            payload: claims,
            protectedHeader: DefaultJWSHeaderImpl(
                algorithm: .EdDSA,
                keyID: keyJWK.kid
            ),
            key: JSONWebKey.JWK(
                keyType: kty,
                keyID: keyJWK.kid,
                x: keyJWK.x.flatMap { Data(fromBase64URL: $0) },
                d: keyJWK.d.flatMap { Data(fromBase64URL: $0) }
            )
        )

        return jwt.jwtString
    }
}
