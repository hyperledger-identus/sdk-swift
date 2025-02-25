// import TestFramework

// final class VerifySdJwt: Feature {
//     override func title() -> String {
//         "Verify SD+JWT presentation"
//     }
    
//     override func description() -> String {
//         "The Edge Agent should be able to receive a verifiable credential from Cloud Agent and then send a presentation to another edge agent who will verify it"
//     }
    
//     func testSdJwtVerification() async throws {
//         currentScenario = Scenario("SDKs JWT Verification")
//             .given("Cloud Agent is connected to Edge Agent")
//             .and("Edge Agent has '1' sd+jwt credentials issued by Cloud Agent")
//             .then("Verifier Edge Agent requests the Edge Agent to verify the SD+JWT credential")
//             .when("Edge Agent sends the present-proof")
//             .then("Verifier Edge Agent should see the verification proof is verified")
//     }
    
//     func testSdJwtWrongClaimsVerification() async throws {
//         currentScenario = Scenario("SDKs JWT Verification")
//             .given("Cloud Agent is connected to Edge Agent")
//             .and("Edge Agent has '1' sd+jwt credentials issued by Cloud Agent")
//             .then("Verifier Edge Agent requests Edge Agent to verify the SD+JWT credential with non-existing claims")
//             .when("Edge Agent sends the present-proof")
//             .then("Verifier Edge Agent should see the verification proof is not verified")
//     }
// }
