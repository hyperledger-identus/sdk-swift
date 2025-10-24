import Domain

extension Pollux {
    public func issueCredential(
        type: String,
        @CredentialClaimsBuilder claims: () -> InputClaim,
        options: [CredentialOperationsOptions]
    ) async throws -> Credential {
        guard
            let requestIdOption = options.first(where: {
                if case .exportableKey = $0 { return true }
                return false
            }),
            case let CredentialOperationsOptions.exportableKey(privateKey) = requestIdOption
        else {
            throw PolluxError.invalidPrismDID
        }
        switch type {
        case "jwt":
            return try JWTIssueCredential(privateKey: privateKey, claims: claims()).issue()
        case "vc+jwt":
            try W3CIssueCredential(claims: claims()).verifyClaims()
            return try JWTIssueCredential(privateKey: privateKey, claims: claims()).issue()
        case "sdjwt":
            return try await SDJWTIssueCredential(privateKey: privateKey, claims: claims()).issue()
        case "vc+sdjwt":
            try W3CIssueCredential(claims: claims()).verifyClaims()
            return try await SDJWTIssueCredential(privateKey: privateKey, claims: claims()).issue()
        default:
            throw PolluxError.invalidCredentialError
        }
    }
}
