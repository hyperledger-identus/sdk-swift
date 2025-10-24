import Core
import Foundation
import JSONWebToken
import Tools

/// `JWTCredential` provides a convenient way to parse the payload of a JWT‑based
/// Verifiable Credential using a JOSE envelope (JWS/JWT). It extracts the JWT
/// payload and decodes it into a strongly typed VC model. This is useful when
/// working with ecosystems that transport VCs in JWT form, as described in the
/// W3C Verifiable Credentials Data Model (VCDM 1.0/1.1/2.0) and related specs.
///
/// Notes
/// - This utility focuses on parsing/decoding. It does not perform cryptographic
///   verification of the JWT/JWS. You should verify signatures and validate keys
///   (e.g., via DID resolution or trusted key material) before trusting contents.
/// - While this helper targets JOSE (JWS/JWT) envelopes, similar patterns apply
///   to COSE/CBOR envelopes if you introduce a corresponding decoder.
///
/// - Conforms to:
///   - `Credential`
///   - `ProvableCredential`
///   - `StorableCredential`
///   - `RevocableCredential`
///
/// - See also:
///   - W3C Verifiable Credentials Data Model 1.0 (2019): https://www.w3.org/TR/2019/REC-vc-data-model-20191119/
///   - W3C Verifiable Credentials Data Model 1.1: https://www.w3.org/TR/vc-data-model-1.1/
///   - W3C Verifiable Credentials Data Model 2.0: https://www.w3.org/TR/vc-data-model-2.0/
///   - JSON Web Token (JWT): https://www.rfc-editor.org/rfc/rfc7519
///   - JSON Web Signature (JWS): https://www.rfc-editor.org/rfc/rfc7515
///   - COSE (CBOR Object Signing and Encryption): https://www.rfc-editor.org/rfc/rfc9052
///   - `DefaultVerifiableCredential`, `JWTEnvelopedVerifiableCredential`, `Credential`, `ProvableCredential`
public struct JWTCredential {
    /// The original JWT compact serialization string (JOSE envelope).
    public let jwtString: String
    /// The parsed JOSE envelope with a `DefaultVerifiableCredential` payload.
    ///
    /// This provides quick access to a broadly compatible VC model without defining
    /// custom generic types.
    public let defaultEnvelop: JWTEnvelopedVerifiableCredential<DefaultVerifiableCredential>

    /// Creates a `JWTCredential` by extracting and decoding the JWT payload.
    ///
    /// - Parameters:
    ///   - jwtString: The JWT compact string containing the VC payload.
    ///   - decoder: A `JSONDecoder` configured for JWT payloads (defaults to `.jwt`).
    /// - Throws: An error if the payload cannot be extracted or decoded.
    public init(jwtString: String, decoder: JSONDecoder = .jwt) throws {
        self.jwtString = jwtString
        let payload: Data = try JWT.getPayload(jwtString: jwtString)
        self.defaultEnvelop = try decoder
            .decode(
                JWTEnvelopedVerifiableCredential<DefaultVerifiableCredential>.self,
                from: payload
            )
    }

    /// Decodes the JWT payload into the requested credential type.
    ///
    /// Supply a concrete VC model (e.g., `DefaultVerifiableCredential`) or your own
    /// strongly typed credential type.
    ///
    /// - Parameter decoder: A `JSONDecoder` configured for JWT payloads (defaults to `.jwt`).
    /// - Returns: The decoded credential of type `T`.
    /// - Throws: An error if decoding fails.
    public func getCredential<T: Codable>(decoder: JSONDecoder = .jwt) throws -> T {
        try decoder.decode(JWTEnvelopedVerifiableCredential<T>.self, from: try getPayload()).vc
    }

    /// Returns the raw JWT payload (claims) as JSON data without verification.
    ///
    /// Use this to perform custom decoding or cryptographic verification with your
    /// own JOSE/COSE tooling.
    ///
    /// - Returns: The unverified payload bytes from the JWT.
    /// - Throws: An error if the payload cannot be extracted.
    public func getPayload() throws -> Data {
        try JWT.getPayload(jwtString: jwtString)
    }
}
