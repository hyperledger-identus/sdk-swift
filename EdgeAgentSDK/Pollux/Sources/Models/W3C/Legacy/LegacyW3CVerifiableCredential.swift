import Core
import Domain
import Foundation

struct LegacyW3CVerifiableCredential {
    let context: Set<String>
    let type: Set<String>
    let id: String
    let issuerDID: DID
    let subjectDID: DID?
    let issuanceDate: Date
    let expirationDate: Date?
    let credentialSchema: VerifiableCredentialTypeContainer?
    let credentialSubject: AnyCodable
    let credentialStatus: VerifiableCredentialTypeContainer?
    let refreshService: VerifiableCredentialTypeContainer?
    let evidence: VerifiableCredentialTypeContainer?
    let termsOfUse: VerifiableCredentialTypeContainer?
    let validFrom: VerifiableCredentialTypeContainer?
    let validUntil: VerifiableCredentialTypeContainer?
    let proof: ProofContainer?
    let aud: Set<String>

    init(
        context: Set<String> = Set(),
        type: Set<String> = Set(),
        id: String,
        issuerDID: DID,
        subjectDID: DID?,
        issuanceDate: Date,
        expirationDate: Date? = nil,
        credentialSchema: VerifiableCredentialTypeContainer? = nil,
        credentialSubject: AnyCodable,
        credentialStatus: VerifiableCredentialTypeContainer? = nil,
        refreshService: VerifiableCredentialTypeContainer? = nil,
        evidence: VerifiableCredentialTypeContainer? = nil,
        termsOfUse: VerifiableCredentialTypeContainer? = nil,
        validFrom: VerifiableCredentialTypeContainer? = nil,
        validUntil: VerifiableCredentialTypeContainer? = nil,
        proof: ProofContainer? = nil,
        aud: Set<String> = Set()
    ) {
        self.context = context
        self.type = type
        self.id = id
        self.issuerDID = issuerDID
        self.subjectDID = subjectDID
        self.issuanceDate = issuanceDate
        self.expirationDate = expirationDate
        self.credentialSchema = credentialSchema
        self.credentialSubject = credentialSubject
        self.credentialStatus = credentialStatus
        self.refreshService = refreshService
        self.evidence = evidence
        self.termsOfUse = termsOfUse
        self.validFrom = validFrom
        self.validUntil = validUntil
        self.proof = proof
        self.aud = aud
    }
}

extension LegacyW3CVerifiableCredential: Credential {
    
    var issuer: String {
        self.issuerDID.string
    }
    
    var subject: String? {
        self.subjectDID?.string
    }
    
    var claims: [Claim] {
        []
//        credentialSubject.map {
//            Claim(key: $0, value: .string($1))
//        }
    }
    
    var properties: [String : Any] {
        var properties = [
            "issuanceDate" : issuanceDate,
            "context" : context,
            "type" : type,
            "id" : id,
            "aud" : aud
        ] as [String : Any]
        
        expirationDate.map { properties["expirationDate"] = $0 }
        credentialSchema.map { properties["schema"] = $0.type }
        credentialStatus.map { properties["credentialStatus"] = $0.type }
        refreshService.map { properties["refreshService"] = $0.type }
        evidence.map { properties["evidence"] = $0.type }
        termsOfUse.map { properties["termsOfUse"] = $0.type }
        validFrom.map { properties["validFrom"] = $0.type }
        validUntil.map { properties["validUntil"] = $0.type }
        proof.map { properties["proof"] = $0 }
        
        return properties
    }
    
    var credentialType: String { "W3C" }
}
