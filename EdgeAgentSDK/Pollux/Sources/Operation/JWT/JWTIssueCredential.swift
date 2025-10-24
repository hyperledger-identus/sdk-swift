import Domain
import JSONWebSignature
import JSONWebToken

public struct JWTIssueCredential {
    let privateKey: PrivateKey
    let claims: InputClaim

    public init(privateKey: PrivateKey, claims: InputClaim) {
        self.privateKey = privateKey
        self.claims = claims
    }

    public func issue() throws -> Credential {
    }

    func checkClaims() throws {
    }
}
