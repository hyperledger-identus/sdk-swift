import Domain
import Foundation
import JSONSchema
import JSONWebToken

struct JWTPresentationExchangeParser: SubmissionDescriptorFormatParser {
    let format = "jwt"
    let verifier: VerifyJWT

    func parse(path: String, presentationData: Data) async throws -> String {
        guard
            let jwt = presentationData.query(string: path)
        else {
            throw PolluxError.credentialPathInvalid(path: path)
        }

        do {
            try await verifier.verifyJWT(jwtString: jwt)
        } catch {
            throw PolluxError.cannotVerifyCredential(credential: jwt, internalErrors: [error])
        }

        return jwt
    }

    func parsePayload(path: String, presentationData: Data) async throws -> Data {
        let jwt = try await parse(path: path, presentationData: presentationData)
        return try JWT.getPayload(jwtString: jwt)
    }

    func parseClaimVerifier(descriptor: PresentationSubmission.Descriptor, presentationData: Data) async throws -> PresentationExchangeClaimVerifier {
        let jwt = try await parse(path: descriptor.path, presentationData: presentationData)
        return JWTVerifierPresentationExchange(
            castor: verifier.castor,
            jwtString: jwt,
            submissionDescriptor: descriptor
        )
    }
}
