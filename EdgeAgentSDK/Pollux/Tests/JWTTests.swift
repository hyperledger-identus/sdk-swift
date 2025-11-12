import Apollo
import Castor
import Domain
import CryptoKit
import EdgeAgent
@testable import Pollux
import XCTest
import secp256k1

final class JWTTests: XCTestCase {

    lazy var apollo = ApolloImpl()
    lazy var castor = CastorImpl(apollo: apollo)
    
    func testParseJWTCredential() throws {
        let validJWTString = "eyJhbGciOiJFUzI1NksifQ.eyJpc3MiOiJkaWQ6cHJpc206MmU0MGZkNjkyYjgzYzE5ZjlhNTUzNjRjMmNhNWJmNjkyOGI4ODU1NGE1YmYxMTc0YTc4ZjY4NDk4ZDgwZGZjNjpDcmNCQ3JRQkVqa0tCV3RsZVMweEVBSktMZ29KYzJWamNESTFObXN4RWlFQ1pDbDV4aUREb3ZsVFlNNVVSeXdHODZPWjc2RWNTY3ZjSEplaHRnbWNKTlFTT2dvR1lYVjBhQzB4RUFSS0xnb0pjMlZqY0RJMU5tc3hFaUVDRUMzTUNPak4xb1lNZjU2ZVVBaTA3NkxGX2hRZDRwbFFib3JKcnBkOHdHY1NPd29IYldGemRHVnlNQkFCU2k0S0NYTmxZM0F5TlRack1SSWhBeTVqVkc4UTRWOHRYV0RoUWNvb2xPTmFIdTZHaW5ockJ6SEtfRXYySW9yNSIsInN1YiI6ImRpZDpwcmlzbTo4ODYwN2Y4YjE3ZWJhZmNhODgwNDdmZDQ0YTMyZTE4NGI1MGYwM2QyNWZhZWQ1ZGRiYWQyZGRjNGYyZjg5YWYzOkNzY0JDc1FCRW1RS0QyRjFkR2hsYm5ScFkyRjBhVzl1TUJBRVFrOEtDWE5sWTNBeU5UWnJNUklncnFDMVhaN2ZsOUpLSjBNT3pTa2hSZFhESHpnSVQzTGJ1MlNLdTJvZWxKVWFJT3gxSzFvY2NDRG14SS05Zm9jRm84emhpTm5BYXBPUGFXQXY0UGg0azZjWkVsd0tCMjFoYzNSbGNqQVFBVUpQQ2dselpXTndNalUyYXpFU0lLNmd0VjJlMzVmU1NpZEREczBwSVVYVnd4ODRDRTl5Mjd0a2lydHFIcFNWR2lEc2RTdGFISEFnNXNTUHZYNkhCYVBNNFlqWndHcVRqMmxnTC1ENGVKT25HUSIsIm5iZiI6MTY4ODA1ODcyNywiZXhwIjoxNjg4MDYyMzI3LCJ2YyI6eyJjcmVkZW50aWFsU2NoZW1hIjp7ImlkIjoiaHR0cHM6XC9cL2s4cy1kZXYuYXRhbGFwcmlzbS5pb1wvcHJpc20tYWdlbnRcL3NjaGVtYS1yZWdpc3RyeVwvc2NoZW1hc1wvMDIwMTY5M2ItNGQ2ZC0zNmVjLWEzN2QtODFkODhlODcyNTM5IiwidHlwZSI6IkNyZWRlbnRpYWxTY2hlbWEyMDIyIn0sImNyZWRlbnRpYWxTdWJqZWN0Ijp7InRlc3QiOiJUZXN0MSIsImlkIjoiZGlkOnByaXNtOjg4NjA3ZjhiMTdlYmFmY2E4ODA0N2ZkNDRhMzJlMTg0YjUwZjAzZDI1ZmFlZDVkZGJhZDJkZGM0ZjJmODlhZjM6Q3NjQkNzUUJFbVFLRDJGMWRHaGxiblJwWTJGMGFXOXVNQkFFUWs4S0NYTmxZM0F5TlRack1SSWdycUMxWFo3Zmw5SktKME1PelNraFJkWERIemdJVDNMYnUyU0t1Mm9lbEpVYUlPeDFLMW9jY0NEbXhJLTlmb2NGbzh6aGlObkFhcE9QYVdBdjRQaDRrNmNaRWx3S0IyMWhjM1JsY2pBUUFVSlBDZ2x6WldOd01qVTJhekVTSUs2Z3RWMmUzNWZTU2lkRERzMHBJVVhWd3g4NENFOXkyN3RraXJ0cUhwU1ZHaURzZFN0YUhIQWc1c1NQdlg2SEJhUE00WWpad0dxVGoybGdMLUQ0ZUpPbkdRIn0sInR5cGUiOlsiVmVyaWZpYWJsZUNyZWRlbnRpYWwiXSwiQGNvbnRleHQiOlsiaHR0cHM6XC9cL3d3dy53My5vcmdcLzIwMThcL2NyZWRlbnRpYWxzXC92MSJdfX0.JZBqArVFvWgj2W0b7vVPSKR3mSH_X-VOC-YQ_jyLZSOEYUkortkRGi41xwA7SPFSqPdSCHl4iagpBir1tYMBOw"
        
        let jwtData = validJWTString.data(using: .utf8)!
        let credential = try LegacyJWTCredential(data: jwtData)
        XCTAssertEqual(credential.claims.map(\.key).sorted(), ["id", "test"].sorted())
        XCTAssertEqual(credential.id, validJWTString)
    }

    func testRevoked() throws {
        let validJWTString = try "eyJhbGciOiJFUzI1NksifQ.eyJpc3MiOiJkaWQ6cHJpc206MmU0MGZkNjkyYjgzYzE5ZjlhNTUzNjRjMmNhNWJmNjkyOGI4ODU1NGE1YmYxMTc0YTc4ZjY4NDk4ZDgwZGZjNjpDcmNCQ3JRQkVqa0tCV3RsZVMweEVBSktMZ29KYzJWamNESTFObXN4RWlFQ1pDbDV4aUREb3ZsVFlNNVVSeXdHODZPWjc2RWNTY3ZjSEplaHRnbWNKTlFTT2dvR1lYVjBhQzB4RUFSS0xnb0pjMlZqY0RJMU5tc3hFaUVDRUMzTUNPak4xb1lNZjU2ZVVBaTA3NkxGX2hRZDRwbFFib3JKcnBkOHdHY1NPd29IYldGemRHVnlNQkFCU2k0S0NYTmxZM0F5TlRack1SSWhBeTVqVkc4UTRWOHRYV0RoUWNvb2xPTmFIdTZHaW5ockJ6SEtfRXYySW9yNSIsInN1YiI6ImRpZDpwcmlzbTo4ODYwN2Y4YjE3ZWJhZmNhODgwNDdmZDQ0YTMyZTE4NGI1MGYwM2QyNWZhZWQ1ZGRiYWQyZGRjNGYyZjg5YWYzOkNzY0JDc1FCRW1RS0QyRjFkR2hsYm5ScFkyRjBhVzl1TUJBRVFrOEtDWE5sWTNBeU5UWnJNUklncnFDMVhaN2ZsOUpLSjBNT3pTa2hSZFhESHpnSVQzTGJ1MlNLdTJvZWxKVWFJT3gxSzFvY2NDRG14SS05Zm9jRm84emhpTm5BYXBPUGFXQXY0UGg0azZjWkVsd0tCMjFoYzNSbGNqQVFBVUpQQ2dselpXTndNalUyYXpFU0lLNmd0VjJlMzVmU1NpZEREczBwSVVYVnd4ODRDRTl5Mjd0a2lydHFIcFNWR2lEc2RTdGFISEFnNXNTUHZYNkhCYVBNNFlqWndHcVRqMmxnTC1ENGVKT25HUSIsIm5iZiI6MTY4ODA1ODcyNywiZXhwIjoxNjg4MDYyMzI3LCJ2YyI6eyJjcmVkZW50aWFsU2NoZW1hIjp7ImlkIjoiaHR0cHM6XC9cL2s4cy1kZXYuYXRhbGFwcmlzbS5pb1wvcHJpc20tYWdlbnRcL3NjaGVtYS1yZWdpc3RyeVwvc2NoZW1hc1wvMDIwMTY5M2ItNGQ2ZC0zNmVjLWEzN2QtODFkODhlODcyNTM5IiwidHlwZSI6IkNyZWRlbnRpYWxTY2hlbWEyMDIyIn0sImNyZWRlbnRpYWxTdWJqZWN0Ijp7InRlc3QiOiJUZXN0MSIsImlkIjoiZGlkOnByaXNtOjg4NjA3ZjhiMTdlYmFmY2E4ODA0N2ZkNDRhMzJlMTg0YjUwZjAzZDI1ZmFlZDVkZGJhZDJkZGM0ZjJmODlhZjM6Q3NjQkNzUUJFbVFLRDJGMWRHaGxiblJwWTJGMGFXOXVNQkFFUWs4S0NYTmxZM0F5TlRack1SSWdycUMxWFo3Zmw5SktKME1PelNraFJkWERIemdJVDNMYnUyU0t1Mm9lbEpVYUlPeDFLMW9jY0NEbXhJLTlmb2NGbzh6aGlObkFhcE9QYVdBdjRQaDRrNmNaRWx3S0IyMWhjM1JsY2pBUUFVSlBDZ2x6WldOd01qVTJhekVTSUs2Z3RWMmUzNWZTU2lkRERzMHBJVVhWd3g4NENFOXkyN3RraXJ0cUhwU1ZHaURzZFN0YUhIQWc1c1NQdlg2SEJhUE00WWpad0dxVGoybGdMLUQ0ZUpPbkdRIn0sInR5cGUiOlsiVmVyaWZpYWJsZUNyZWRlbnRpYWwiXSwiQGNvbnRleHQiOlsiaHR0cHM6XC9cL3d3dy53My5vcmdcLzIwMThcL2NyZWRlbnRpYWxzXC92MSJdfX0.JZBqArVFvWgj2W0b7vVPSKR3mSH_X-VOC-YQ_jyLZSOEYUkortkRGi41xwA7SPFSqPdSCHl4iagpBir1tYMBOw".tryToData()
        let credential = try LegacyJWTCredential(data: validJWTString)
        let encodedList = Data(fromBase64URL: "H4sIAAAAAAAA_-3BMQ0AAAACIGf_0MbwARoAAAAAAAAAAAAAAAAAAADgbbmHB0sAQAAA")!
        XCTAssertFalse(try LegacyJWTRevocationCheck(credential: credential)
            .verifyRevocationOnEncodedList(encodedList, index: 94567))
    }

    func testIssueJWTCredential() throws {
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
                StringClaim(key: "name", value: "John Doe")
                ObjectClaim(key: "grades") {
                    NumberClaim(key: "mathematic", value: 8)
                    NumberClaim(key: "physics", value: 7.2)
                    NumberClaim(key: "english", value: 9.9)
                }
                BoolClaim(key: "approved", value: true)
                ArrayClaim(key: "professors")  {
                    ArrayValueClaim.string("Professor Jane Doe")
                    ArrayValueClaim.string("Professor Josef Doe")
                }
            })
        }

        let credential = try JWTIssueCredential(privateKey: privateKey.exporting!, claims: w3cClaims).issue()
        print(credential.id)
    }
}

