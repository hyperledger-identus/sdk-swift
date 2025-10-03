import Core
import Domain
import Foundation

/**
 A struct representing a JWT credential payload.

 This payload includes the issuer (`iss`), subject (`sub`), and the verifiable credential (`verifiableCredential`).

 - Note: This struct conforms to the JSON Web Token (JWT) format. For more information, see https://jwt.io/introduction/.
 */
struct JWTPayload {

    /**
     A struct representing the verifiable credential in a JWT credential payload.
     */
    struct JWTVerfiableCredential {
        let context: Set<String>
        let type: Set<String>
        let credentialSchema: VerifiableCredentialTypeContainer?
        let credentialSubject: AnyCodable
        let refreshService: VerifiableCredentialTypeContainer?
        let evidence: VerifiableCredentialTypeContainer?
        let termsOfUse: VerifiableCredentialTypeContainer?
        let credentialStatus: LegacyJWTRevocationStatus?

        /**
         Initializes a new instance of `JWTVerifiableCredential`.

         - Parameters:
            - context: A set of JSON-LD contexts.
            - type: A set of types associated with the credential.
            - credentialSchema: The credential schema.
            - credentialSubject: The credential subject, represented as a dictionary of key-value pairs.
            - credentialStatus: The credential status.
            - refreshService: The refresh service.
            - evidence: The evidence associated with the credential.
            - termsOfUse: The terms of use associated with the credential.
         */
        init(
            context: Set<String> = Set(),
            type: Set<String> = Set(),
            credentialSchema: VerifiableCredentialTypeContainer? = nil,
            credentialSubject: AnyCodable,
            credentialStatus: LegacyJWTRevocationStatus? = nil,
            refreshService: VerifiableCredentialTypeContainer? = nil,
            evidence: VerifiableCredentialTypeContainer? = nil,
            termsOfUse: VerifiableCredentialTypeContainer? = nil
        ) {
            self.context = context
            self.type = type
            self.credentialSchema = credentialSchema
            self.credentialSubject = credentialSubject
            self.credentialStatus = credentialStatus
            self.refreshService = refreshService
            self.evidence = evidence
            self.termsOfUse = termsOfUse
        }
    }

    let iss: DID
    let sub: String?
    let verifiableCredential: JWTVerfiableCredential
    let nbf: Date?
    let exp: Date?
    let jti: String
    let aud: Set<String>
    let originalJWTString: String

    /**
     Initializes a new instance of `JWTCredentialPayload`.

     - Parameters:
        - iss: The issuer of the credential.
        - sub: The subject of the credential.
        - verifiableCredential: The verifiable credential contained within the payload.
        - nbf: The time before which the credential is not valid.
        - exp: The time after which the credential is not valid.
        - jti: The unique identifier for the credential.
        - aud: The intended audience for the credential.
     */
    init(
        iss: DID,
        sub: String? = nil,
        verifiableCredential: JWTVerfiableCredential,
        nbf: Date?,
        exp: Date? = nil,
        jti: String,
        aud: Set<String> = Set(),
        originalJWTString: String
    ) {
        self.iss = iss
        self.sub = sub
        self.verifiableCredential = verifiableCredential
        self.nbf = nbf
        self.exp = exp
        self.jti = jti
        self.aud = aud
        self.originalJWTString = originalJWTString
    }
}
