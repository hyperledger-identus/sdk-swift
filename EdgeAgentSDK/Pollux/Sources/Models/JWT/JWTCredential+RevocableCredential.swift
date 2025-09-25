import Core
import Domain
import Foundation

extension JWTCredential: RevocableCredential {
    public var canBeRevoked: Bool {
        return defaultEnvelop.vc.getAsStatusListEntry(for: .revocation) != nil
    }

    public var canBeSuspended: Bool {
        return defaultEnvelop.vc.getAsStatusListEntry(for: .suspension) != nil
    }

    public var isRevoked: Bool {
        get async throws {
            guard
                let revocationStatus = defaultEnvelop.vc.getAsStatusListEntry(for: .revocation)
            else { return false }

            return try await StatusCheckOperation(statusListEntry: revocationStatus).checkStatus()
        }
    }

    public var isSuspended: Bool {
        get async throws {
            guard
                let suspensionStatus = defaultEnvelop.vc.getAsStatusListEntry(for: .suspension)
            else { return false }

            return try await StatusCheckOperation(statusListEntry: suspensionStatus).checkStatus()
        }
    }
}

extension VerifiableCredential {
    func getAsStatusListEntry(for purpose: StatusListEntry.CredentialStatusPurpose) -> StatusListEntry? {
        let statusListEntry: OneOrMany<StatusListEntry>? = try? credentialStatus?.decodedAs()
        return statusListEntry?.array.first { $0.statusPurpose == purpose }
    }
}
