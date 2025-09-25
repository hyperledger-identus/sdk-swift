import Core
import Domain
import Foundation

extension LegacyW3CVerifiableCredential: Codable {
    enum CodingKeys: String, CodingKey {
        case context = "@context"
        case type = "@type"
        case id
        case issuer
        case subject
        case issuanceDate
        case expirationDate
        case validFrom
        case validUntil
        case proof
        case credentialSubject
        case credentialStatus
        case credentialSchema
        case refreshService
        case evidence
        case termsOfUse
        case aud
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.context, forKey: .context)
        if self.type.count != 1 {
            try container.encode(self.type, forKey: .type)
        } else if let value = self.type.first {
            try container.encode(value, forKey: .type)
        }
        try container.encode(self.id, forKey: .id)
        try container.encode(self.issuer, forKey: .issuer)
        if let subject = self.subject {
            try container.encode(subject, forKey: .subject)
        }
        try container.encode(self.issuanceDate, forKey: .issuanceDate)
        try container.encode(self.expirationDate, forKey: .expirationDate)
        try container.encode(self.validFrom, forKey: .validFrom)
        try container.encode(self.validUntil, forKey: .validUntil)
        try container.encode(self.proof, forKey: .proof)
        try container.encode(self.aud, forKey: .aud)
        try container.encode(self.credentialSubject, forKey: .credentialSubject)
        try container.encode(self.credentialStatus, forKey: .credentialStatus)
        try container.encode(self.credentialSchema, forKey: .credentialSchema)
        try container.encode(self.refreshService, forKey: .refreshService)
        try container.encode(self.evidence, forKey: .evidence)
        try container.encode(self.termsOfUse, forKey: .termsOfUse)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let context = (try? container.decode(Set<String>.self, forKey: .context)) ?? Set()
        let type: Set<String>
        if let value = try? container.decode(String.self, forKey: .type) {
            type = Set([value])
        } else {
            type = try container.decode(Set<String>.self, forKey: .type)
        }
        let id = try container.decode(String.self, forKey: .id)
        let didString = try container.decode(String.self, forKey: .issuer)
        let issuer = try DID(string: didString)
        let issuanceDate = try container.decode(Date.self, forKey: .issuanceDate)
        let expirationDate = try? container.decode(Date.self, forKey: .expirationDate)
        let validFrom = try? container.decode(VerifiableCredentialTypeContainer.self, forKey: .validFrom)
        let validUntil = try? container.decode(VerifiableCredentialTypeContainer.self, forKey: .validUntil)
        let proof = try? container.decode(ProofContainer.self, forKey: .proof)
        let aud = (try? container.decode(Set<String>.self, forKey: .proof)) ?? Set()
        let credentialSubject = try container.decode(AnyCodable.self, forKey: .credentialSubject)
        let subjectString = try? container.decode(
            String.self,
            forKey: .subject
        )
        let subject = subjectString.flatMap { try? DID(string: $0) }
        let credentialStatus = try? container.decode(
            VerifiableCredentialTypeContainer.self,
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
            id: id,
            issuerDID: issuer,
            subjectDID: subject,
            issuanceDate: issuanceDate,
            expirationDate: expirationDate,
            credentialSchema: credentialSchema,
            credentialSubject: credentialSubject,
            credentialStatus: credentialStatus,
            refreshService: refreshService,
            evidence: evidence,
            termsOfUse: termsOfUse,
            validFrom: validFrom,
            validUntil: validUntil,
            proof: proof,
            aud: aud
        )
    }
}
