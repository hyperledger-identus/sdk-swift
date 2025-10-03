import Foundation

struct LegacyJWTRevocationStatus: Codable {
    enum CredentialStatusListType: String, Codable {
        case statusList2021Entry = "StatusList2021Entry"
    }
    
    enum CredentialStatusPurpose: String, Codable {
        case revocation = "Revocation"
        case suspension = "Suspension"
    }
    
    let id: String
    let type: String
    let statusPurpose: CredentialStatusPurpose
    let statusListIndex: Int
    let statusListCredential: String
}

struct JWTRevocationStatusListCredential: Codable {
    enum CodingKeys: String, CodingKey {
        case context = "@context"
        case type
        case issuer
        case id
        case issuanceDate
        case credentialSubject
        case proof
    }
    
    struct StatusListCredentialSubject: Codable {
        let type: String
        let statusPurpose: String
        let encodedList: String
    }
    
    let context: Set<String>
    let type: Set<String>
    let id: String
    let issuer: String
    let issuanceDate: Date
    let credentialSubject: StatusListCredentialSubject
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.context, forKey: .context)
        try container.encode(self.type, forKey: .type)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.issuer, forKey: .issuer)
        try container.encode(self.issuanceDate, forKey: .issuanceDate)
        try container.encode(self.credentialSubject, forKey: .credentialSubject)
    }
    
    init(
        context: Set<String>,
        type: Set<String>,
        id: String,
        issuer: String,
        issuanceDate: Date,
        credentialSubject: StatusListCredentialSubject
    ) {
        self.context = context
        self.type = type
        self.id = id
        self.issuer = issuer
        self.issuanceDate = issuanceDate
        self.credentialSubject = credentialSubject
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let context = (try? container.decode(Set<String>.self, forKey: .context)) ?? Set<String>()
        let type: Set<String>
        if let value = try? container.decode(String.self, forKey: .type) {
            type = Set([value])
        } else {
            type = (try? container.decode(Set<String>.self, forKey: .type)) ?? Set<String>()
        }
        let id = try container.decode(String.self, forKey: .id)
        let issuer =  try container.decode(String.self, forKey: .issuer)
        let issuanceDate = try container.decode(Date.self, forKey: .issuanceDate)
        let credentialSubject = try container.decode(StatusListCredentialSubject.self, forKey: .credentialSubject)
        
        self.init(
            context: context,
            type: type,
            id: id,
            issuer: issuer,
            issuanceDate: issuanceDate,
            credentialSubject: credentialSubject
        )
    }
}
