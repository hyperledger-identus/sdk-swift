import Core
import Domain
import Foundation
import JSONWebAlgorithms
import JSONWebToken

struct VerifyJWT {
    let castor: Castor

    func verifyJWT(jwtString: String) async throws -> Bool {
        let jwtString = try jwtString.parseIfUrl()
        try await verifyJWTCredentialRevocation(jwtString: jwtString)
        let payload: DefaultJWTClaimsImpl = try JWT.getPayload(jwtString: jwtString)
        guard let issuer = payload.iss else {
            throw PolluxError.requiresThatIssuerExistsAndIsAPrismDID
        }

        let issuerDID = try DID(string: issuer)
        let issuerKeys = try await castor.getDIDPublicKeys(did: issuerDID)

        ES256KVerifier.bouncyCastleFailSafe = true

        let validations = await issuerKeys
            .compactMap(\.exporting)
            .asyncCompactMap {
                try? await JWT.verify(jwtString: jwtString, senderKey: $0.jwk.toJoseJWK())
            }
        ES256KVerifier.bouncyCastleFailSafe = false
        return !validations.isEmpty
    }

    private func verifyJWTCredentialRevocation(jwtString: String) async throws {
        guard let credential = try? LegacyJWTCredential(data: jwtString.tryToData()) else {
            return
        }
        let isRevoked = try await credential.isRevoked
        let isSuspended = try await credential.isSuspended
        guard !isRevoked else {
            throw PolluxError.credentialIsRevoked(jwtString: jwtString)
        }
        guard !isSuspended else {
            throw PolluxError.credentialIsSuspended(jwtString: jwtString)
        }
    }
}
