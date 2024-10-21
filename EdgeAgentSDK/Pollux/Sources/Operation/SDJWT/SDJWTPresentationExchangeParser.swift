import Domain
import Foundation
import JSONSchema
import JSONWebToken
import eudi_lib_sdjwt_swift

struct SDJWTPresentationExchangeParser: SubmissionDescriptorFormatParser {
    let format = "sd_jwt"
    let verifier: VerifySDJWT

    func parse(path: String, presentationData: Data) async throws -> String {
        guard
            let sdjwt = presentationData.query(string: path)
        else {
            throw PolluxError.credentialPathInvalid(path: path)
        }

        guard try await verifier.verifySDJWT(sdjwtString: sdjwt) else {
            throw PolluxError.cannotVerifyCredential(credential: sdjwt, internalErrors: [])
        }

        return sdjwt
    }

    func parsePayload(path: String, presentationData: Data) async throws -> Data {
        let sdjwt = try await parse(path: path, presentationData: presentationData)
        let json = try CompactParser(serialisedString: sdjwt)
            .getSignedSdJwt()
            .recreateClaims()
            .recreatedClaims

        return try json.rawData()
    }

    func parseClaimVerifier(descriptor: PresentationSubmission.Descriptor, presentationData: Data) async throws -> PresentationExchangeClaimVerifier {
        let sdjwt = try await parse(path: descriptor.path, presentationData: presentationData)
        return SDJWTClaimVerifier(
            sdjwtString: sdjwt,
            submissionDescriptor: descriptor
        )
    }

    func parseCredential(descriptor: PresentationSubmission.Descriptor, presentationData: Data) async throws -> any Credential {
        let sdjwt = try await parse(path: descriptor.path, presentationData: presentationData)
        return try SDJWTCredential(sdjwtString: sdjwt)
    }
}
