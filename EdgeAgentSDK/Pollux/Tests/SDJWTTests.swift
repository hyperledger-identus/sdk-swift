import Apollo
import Castor
import Domain
import EdgeAgent
@testable import Pollux
import XCTest

final class SDJWTTests: XCTestCase {

    lazy var apollo = ApolloImpl()
    lazy var castor = CastorImpl(apollo: apollo)

    func testParseSDJWTCredential() throws {
        let validJWTString = "eyJ0eXAiOiJzZCtqd3QiLCJhbGciOiJFUzI1NiJ9.eyJpZCI6IjEyMzQiLCJfc2QiOlsiYkRUUnZtNS1Zbi1IRzdjcXBWUjVPVlJJWHNTYUJrNTdKZ2lPcV9qMVZJNCIsImV0M1VmUnlsd1ZyZlhkUEt6Zzc5aGNqRDFJdHpvUTlvQm9YUkd0TW9zRmsiLCJ6V2ZaTlMxOUF0YlJTVGJvN3NKUm4wQlpRdldSZGNob0M3VVphYkZyalk4Il0sIl9zZF9hbGciOiJzaGEtMjU2In0.n27NCtnuwytlBYtUNjgkesDP_7gN7bhaLhWNL4SWT6MaHsOjZ2ZMp987GgQRL6ZkLbJ7Cd3hlePHS84GBXPuvg~WyI1ZWI4Yzg2MjM0MDJjZjJlIiwiZmlyc3RuYW1lIiwiSm9obiJd~WyJjNWMzMWY2ZWYzNTg4MWJjIiwibGFzdG5hbWUiLCJEb2UiXQ~WyJmYTlkYTUzZWJjOTk3OThlIiwic3NuIiwiMTIzLTQ1LTY3ODkiXQ~"

        let credential = try SDJWTCredential(sdjwtString: validJWTString)
        XCTAssertEqual(credential.claims.map(\.key).sorted(), ["firstname", "lastname", "ssn"].sorted())
        XCTAssertEqual(credential.id, validJWTString)
    }

    func testSDJWTIssueCredentialMapping() throws {
        @CredentialClaimsBuilder var w3c: InputClaim {
            W3CV2ContextClaim(strings: Set(["Testing"]))
            W3CIssuerClaim(id: "did:testing:issuer")
            W3CCredentialSubjectClaim(subject: {
                StringClaim(key: "testDisclosable", value: "testThis", disclosable: true)
                StringClaim(key: "testPlain", value: "plain", disclosable: false)
            })
        }

        let valueSdJwt = try w3c.toSdJwtClaim()
        let encoded = try JSONEncoder.normalized.encode(valueSdJwt)
        try print(encoded.toString())
    }

    func testSDJWTIssuance() async throws {
        let privateKey = try apollo.createPrivateKey(parameters: [
            KeyProperties.type.rawValue: "EC",
            KeyProperties.curve.rawValue: KnownKeyCurves.secp256k1.rawValue,
            KeyProperties.rawKey.rawValue: Data(base64URLEncoded: "4nMn2i4zJfcQQx4Su_0gTNfcqDAdQAU6DuvquIca2VI")!.base64Encoded()
        ])

        @CredentialClaimsBuilder var w3cClaims: InputClaim {
            W3CV2ContextClaim() // This already adds the default required context
            W3CIssuerClaim(id: "did:example:issuer")
            W3CTypeClaim()
            StringClaim(key: "name", value: "University Degree")
            W3CCredentialSubjectClaim(subject: {
                StringClaim(key: "id", value: "did:example:subject")
                StringClaim(key: "name", value: "John Doe", disclosable: true)
                ObjectClaim(key: "grades", disclosable: true) {
                    NumberClaim(key: "mathematic", value: 8)
                    NumberClaim(key: "physics", value: 7.2)
                    NumberClaim(key: "english", value: 9.9)
                }
                BoolClaim(key: "approved", value: true, disclosable: true)
                ArrayClaim(key: "professors", disclosable: true)  {
                    ArrayValueClaim.string("Professor Jane Doe")
                    ArrayValueClaim.string("Professor Josef Doe")
                }
            })
        }

        let issuingOperation = SDJWTIssueCredential(privateKey: privateKey.exporting!, claims: w3cClaims)
        let credential = try await issuingOperation.issue()
        print(credential.id)
    }
}
