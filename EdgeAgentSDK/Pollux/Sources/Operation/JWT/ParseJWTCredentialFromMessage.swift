import Foundation

struct ParseJWTCredentialFromMessage {
    static func parse(issuerCredentialData: Data) throws -> LegacyJWTCredential {
        try LegacyJWTCredential(data: issuerCredentialData)
    }
}
