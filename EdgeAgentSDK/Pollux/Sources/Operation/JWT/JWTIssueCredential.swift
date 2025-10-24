import Core
import Domain
import Foundation
import JSONWebAlgorithms
import JSONWebSignature
import JSONWebToken

public struct JWTIssueCredential {
    let privateKey: ExportableKey
    let claims: InputClaim
    let encoder: JSONEncoder

    public init(privateKey: ExportableKey, claims: InputClaim, encoder: JSONEncoder = .normalized) {
        self.privateKey = privateKey
        self.claims = claims
        self.encoder = encoder
    }

    public func issue() throws -> Credential {
        let payload = try encoder.encode(claims.value)
        let jwk = try privateKey.jwk.toJoseJWK()
        let jwt = try JWT(
            payload: payload,
            format: .jws(
                JWS.init(
                    payload: payload,
                    key: jwk
                )
            )
        )
        return try JWTCredential(jwtString: jwt.jwtString)
    }
}
