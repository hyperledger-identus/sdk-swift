import Core
import Domain
import eudi_lib_sdjwt_swift

public struct SDJWTIssueCredential {
    let claims: InputClaim
    let privateKey: ExportableKey

    public init(privateKey: ExportableKey, claims: InputClaim) {
        self.claims = claims
        self.privateKey = privateKey
    }

    public func issue() async throws -> Credential {
        let sdjwtClaims = try SDJWTClaimSerializer(input: claims)
        let jwk = try privateKey.jwk.toJoseJWK()
        let sdjwt = try await SDJWTIssuer.issue(
            issuersPrivateKey: jwk,
            header: getHeaderForKey(key: jwk)) {
                sdjwtClaims
            }
        return try SDJWTCredential(sdjwtString: sdjwt.serialisation)
    }
}

