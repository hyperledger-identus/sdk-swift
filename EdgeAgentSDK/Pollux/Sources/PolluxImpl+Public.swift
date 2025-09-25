import Core
import Domain
import Foundation

extension PolluxImpl: Pollux {
    public func restoreCredential(restorationIdentifier: String, credentialData: Data) throws -> Credential {
        do {
            switch restorationIdentifier {
            case "sd-jwt+credential":
                return try SDJWTCredential(sdjwtString: credentialData.tryToString())
            case "jwt+credential":
                return try JSONDecoder().decode(LegacyJWTCredential.self, from: credentialData)
            case "w3c+credential":
                return try JSONDecoder().decode(LegacyW3CVerifiableCredential.self, from: credentialData)
            case "anon+credential":
                return try JSONDecoder().decode(AnoncredsCredentialStack.self, from: credentialData)
            default:
                throw PolluxError.invalidCredentialError
            }
        } catch {
            print(error)
            throw error
        }
    }
}
