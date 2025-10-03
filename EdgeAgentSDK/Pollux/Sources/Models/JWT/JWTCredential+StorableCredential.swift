import Domain
import Foundation

extension JWTCredential: StorableCredential {
    public var storingId: String {
        jwtString
    }
    
    public var recoveryId: String {
        "jwt+vc"
    }
    
    public var credentialData: Data {
        (try? jwtString.tryToData()) ?? Data()
    }
    
    public var queryIssuer: String? {
        defaultEnvelop.iss ?? defaultEnvelop.vc.issuer.id
    }

    // TODO: This should be an array of Subjects
    public var querySubject: String? {
        defaultEnvelop.sub
    }
    
    public var queryCredentialCreated: Date? {
        defaultEnvelop.vc.validFrom ?? defaultEnvelop.nbf
    }
    
    public var queryCredentialUpdated: Date? {
        nil
    }

    // TODO: This should be an array of Schemas
    public var queryCredentialSchema: String? {
        guard let schema = defaultEnvelop.vc.credentialSchema else { return nil }
        return schema.array.compactMap { $0.type?.array }.flatMap { $0 }.first
    }
    
    public var queryValidUntil: Date? {
        defaultEnvelop.vc.validUntil ?? defaultEnvelop.exp
    }
    
    public var queryRevoked: Bool? {
        nil
    }
    
    public var queryAvailableClaims: [String] {
        []
    }
}
