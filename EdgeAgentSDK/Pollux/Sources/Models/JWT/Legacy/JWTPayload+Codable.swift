import Core
import Domain
import Foundation

extension JWTPayload.JWTVerfiableCredential: Codable {
    enum CodingKeys: String, CodingKey {
        case context = "@context"
        case type = "@type"
        case credentialSubject
        case credentialStatus
        case credentialSchema
        case refreshService
        case evidence
        case termsOfUse
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(self.context, forKey: .context)
        if self.type.count != 1 {
            try container.encode(self.type, forKey: .type)
        } else if let value = self.type.first {
            try container.encode(value, forKey: .type)
        }
        try container.encode(self.credentialSubject, forKey: .credentialSubject)
        try container.encode(self.credentialStatus, forKey: .credentialStatus)
        try container.encode(self.credentialSchema, forKey: .credentialSchema)
        try container.encode(self.refreshService, forKey: .refreshService)
        try container.encode(self.evidence, forKey: .evidence)
        try container.encode(self.termsOfUse, forKey: .termsOfUse)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let context = (try? container.decode(Set<String>.self, forKey: .context)) ?? Set<String>()
        let type: Set<String>
        if let value = try? container.decode(String.self, forKey: .type) {
            type = Set([value])
        } else {
            type = (try? container.decode(Set<String>.self, forKey: .type)) ?? Set<String>()
        }
        let credentialSubject = try container.decode(AnyCodable.self, forKey: .credentialSubject)
        let credentialStatus = try? container.decode(
            LegacyJWTRevocationStatus.self,
            forKey: .credentialStatus
        )
        let credentialSchema = try? container.decode(
            VerifiableCredentialTypeContainer.self,
            forKey: .credentialSchema
        )
        let refreshService = try? container.decode(
            VerifiableCredentialTypeContainer.self,
            forKey: .refreshService
        )
        let evidence = try? container.decode(
            VerifiableCredentialTypeContainer.self,
            forKey: .evidence
        )
        let termsOfUse = try? container.decode(
            VerifiableCredentialTypeContainer.self,
            forKey: .termsOfUse
        )
        self.init(
            context: context,
            type: type,
            credentialSchema: credentialSchema,
            credentialSubject: credentialSubject,
            credentialStatus: credentialStatus,
            refreshService: refreshService,
            evidence: evidence,
            termsOfUse: termsOfUse
        )
    }
}

extension JWTPayload: Codable {
    enum CodingKeys: String, CodingKey {
        case iss
        case sub
        case verfiableCredential = "vc"
        case nbf
        case exp
        case jti
        case aud
        case originalJWTString
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.iss.string, forKey: .iss)
        try container.encode(self.sub, forKey: .sub)
        try container.encode(self.verifiableCredential, forKey: .verfiableCredential)
        try container.encode(self.nbf, forKey: .nbf)
        try container.encode(self.exp, forKey: .exp)
        try container.encode(self.jti, forKey: .jti)
        try container.encode(self.aud, forKey: .aud)
        try container.encode(self.originalJWTString, forKey: .originalJWTString)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let didString = try container.decode(String.self, forKey: .iss)
        let iss = try DID(string: didString)
        let sub = try? container.decode(String.self, forKey: .sub)
        let verifiableCredential = try container.decode(JWTVerfiableCredential.self, forKey: .verfiableCredential)
        let nbf = try? container.decode(
            Date.self,
            forKey: .nbf
        )
        let exp = try? container.decode(
            Date.self,
            forKey: .exp
        )
        let jti = (try? container.decode(
            String.self,
            forKey: .jti
        )) ?? ""
        let aud = (try? container.decode(
            Set<String>.self,
            forKey: .aud
        )) ?? Set<String>()
        let originalJWTString = (try? container.decode(
            String.self,
            forKey: .originalJWTString
        )) ?? ""

        self.init(
            iss: iss,
            sub: sub,
            verifiableCredential: verifiableCredential,
            nbf: nbf,
            exp: exp,
            jti: jti,
            aud: aud,
            originalJWTString: originalJWTString
        )
    }
}
