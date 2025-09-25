import Domain
import Foundation

extension LegacyJWTCredential: StorableCredential {
    public var storingId: String {
        jwtString
    }
    
    public var recoveryId: String {
        "jwt+credential"
    }
    
    public var credentialData: Data {
        (try? JSONEncoder().encode(self)) ?? Data()
    }
    
    public var queryIssuer: String? {
        issuer
    }
    
    public var querySubject: String? {
        subject
    }
    
    public var queryCredentialCreated: Date? {
        nil
    }
    
    public var queryCredentialUpdated: Date? {
        nil
    }
    
    public var queryCredentialSchema: String? {
        jwtVerifiableCredential.verifiableCredential.credentialSchema?.id
    }
    
    public var queryValidUntil: Date? {
        jwtVerifiableCredential.exp
    }
    
    public var queryRevoked: Bool? {
        nil
    }
    
    public var queryAvailableClaims: [String] {
        claims.map(\.key)
    }
}
