import Domain

extension Pollux {
    func issueCredential(
        type: String,
        @CredentialClaimsBuilder claims: () -> InputClaim,
        options: [CredentialOperationsOptions]
    ) async throws -> Credential {
        switch type {
        case "jwt":
            
        }
    }
}
