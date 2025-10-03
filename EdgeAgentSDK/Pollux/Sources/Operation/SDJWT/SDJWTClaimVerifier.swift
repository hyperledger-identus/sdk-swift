import Domain
import Foundation
import eudi_lib_sdjwt_swift

struct SDJWTClaimVerifier: PresentationExchangeClaimVerifier {
    let sdjwtString: String
    let submissionDescriptor: PresentationSubmission.Descriptor

    func verifyClaim(inputDescriptor: InputDescriptor) throws {
        let payload = try CompactParser()
            .getSignedSdJwt(serialisedString: sdjwtString)
            .recreateClaims()
            .recreatedClaims
            .rawData()
        try VerifyJsonClaim.verify(inputDescriptor: inputDescriptor, jsonData: payload)
    }
}
