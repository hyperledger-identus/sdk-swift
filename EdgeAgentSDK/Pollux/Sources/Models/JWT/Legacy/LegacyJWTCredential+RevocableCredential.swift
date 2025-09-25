import Domain
import Foundation

extension LegacyJWTCredential: RevocableCredential {
    public var canBeRevoked: Bool {
        self.jwtVerifiableCredential.verifiableCredential.credentialStatus?.statusPurpose == .revocation
    }

    public var canBeSuspended: Bool {
        self.jwtVerifiableCredential.verifiableCredential.credentialStatus?.statusPurpose == .suspension
    }

    public var isRevoked: Bool {
        get async throws {
            guard canBeRevoked else { return false }
            return try await LegacyJWTRevocationCheck(credential: self).checkIsRevoked()
        }
    }

    public var isSuspended: Bool {
        get async throws {
            guard canBeSuspended else { return false }
            return try await LegacyJWTRevocationCheck(credential: self).checkIsRevoked()
        }
    }
}
