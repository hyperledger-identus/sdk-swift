import Core
import Foundation

/// A generic Linked Data Proof container for Verifiable Credentials and Presentations
///
/// `DefaultLinkedDataProof` models a proof object as used in the W3C Verifiable
/// Credentials (VC) and Verifiable Presentations (VP) data model. It is designed
/// to accommodate common proof suites (e.g., JWS-based and Data Integrity suites)
/// by capturing the typical fields while preserving the original JSON for
/// round‑tripping.
///
/// This type is intentionally flexible: it can represent a proof attached to a VC
/// (where `proofPurpose` is commonly `assertionMethod`) or a VP (commonly
/// `authentication`, and where `challenge`/`domain` may be present).
///
/// - Fields:
///   - `type`: The proof suite identifier (e.g., `Ed25519Signature2020`,
///     `JsonWebSignature2020`, `EcdsaSecp256k1RecoverySignature2020`).
///   - `created`: Optional timestamp indicating when the proof was created.
///   - `verificationMethod`: Optional DID URL (or URI) identifying the verification
///     method (public key material) used to generate the proof.
///   - `proofPurpose`: Optional purpose of the proof (commonly `assertionMethod`
///     for VCs or `authentication` for VPs).
///   - `jws`: Optional compact JWS string used by JWS-based proof suites.
///   - `proofValue`: Optional multibase-encoded proof value used by Data Integrity
///     proof suites.
///   - `challenge`: Optional anti-replay challenge (commonly used in VP proofs).
///   - `domain`: Optional domain or audience binding (commonly used with VPs).
///   - `nonce`: Optional nonce value (suite-dependent).
///   - `raw`: If provided during decoding, contains the original JSON for lossless
///     round‑tripping. When present, encoding will prefer `raw` verbatim.
///
/// - Codable Behavior:
///   - Decoding: Known fields are decoded if present; the entire proof object is
///     also captured into `raw` for preservation of unknown fields or suite-specific
///     extensions.
///   - Encoding: If `raw` is set, it is encoded verbatim to preserve the original
///     representation. Otherwise, only the known fields are encoded.
///
/// - Conforms to:
///   - `RawCodable`, `Codable`
///
/// - Usage:
///   ```swift
///   struct VerifiableCredential: RawCodable {
///       var proof: DefaultLinkedDataProof
///   }
///
///   struct VerifiablePresentation: RawCodable {
///       var proof: DefaultLinkedDataProof
///   }
///
///   // Example access:
///   switch proof.proofPurpose {
///   case .some("assertionMethod"): /* VC proof */ break
///   case .some("authentication"):   /* VP proof */ break
///   default: break
///   }
///
///   if let jws = proof.jws { /* handle JWS-based suites */ }
///   if let value = proof.proofValue { /* handle Data Integrity suites */ }
///   ```
///
/// - Notes:
///   - `created` is a `Date`; ensure your `JSONDecoder`/`JSONEncoder` is configured
///     with the appropriate date strategies (e.g., ISO‑8601) consistent with your
///     ecosystem.
///   - Different suites populate either `jws` or `proofValue`; some may include
///     additional fields which will be preserved inside `raw`.
///   - Some credentials/presentations may carry multiple proofs; model those as
///     an array of `DefaultLinkedDataProof` when needed.
///
/// - See also:
///   - W3C Verifiable Credentials Data Model: https://www.w3.org/TR/vc-data-model/
///   - W3C Verifiable Credentials Data Integrity: https://www.w3.org/TR/vc-data-integrity/
///   - `RawCodable`, `Codable`
public struct DefaultLinkedDataProof: RawCodable {

    enum CodingKeys: CodingKey {
        case type
        case created
        case verificationMethod
        case proofPurpose
        case jws
        case proofValue
        case challenge
        case domain
        case nonce
    }

    /// The proof suite identifier (e.g., "Ed25519Signature2020", "JsonWebSignature2020").
    public var type: String
    /// When the proof was created. Use ISO‑8601 decoding to match VC/VP conventions.
    public var created: Date?
    /// DID URL or URI identifying the verification method (public key) used to generate the proof.
    public var verificationMethod: String?
    /// Purpose of the proof (commonly "assertionMethod" for VCs or "authentication" for VPs).
    public var proofPurpose: String?
    /// Compact JWS value for JWS-based proof suites (e.g., JsonWebSignature2020).
    public var jws: String?
    /// Multibase-encoded proof value for Data Integrity suites (e.g., Ed25519Signature2020).
    public var proofValue: String?
    /// Anti-replay challenge, typically required for VP proofs.
    public var challenge: String?
    /// Domain or audience binding associated with the proof, often used with VPs.
    public var domain: String?
    /// Optional nonce used by some proof suites.
    public var nonce: String?
    public var raw: AnyCodable?

    /// Creates a new Linked Data Proof.
    ///
    /// - Parameters:
    ///   - type: The proof suite identifier.
    ///   - created: When the proof was created.
    ///   - verificationMethod: DID URL or URI of the verification method (public key).
    ///   - proofPurpose: Purpose of the proof (e.g., "assertionMethod" or "authentication").
    ///   - jws: Compact JWS value for JWS-based suites.
    ///   - proofValue: Multibase-encoded value for Data Integrity suites.
    ///   - challenge: Anti-replay challenge (commonly for VP proofs).
    ///   - domain: Domain or audience binding (commonly for VPs).
    ///   - nonce: Optional nonce used by some suites.
    public init(
        type: String,
        created: Date? = nil,
        verificationMethod: String? = nil,
        proofPurpose: String? = nil,
        jws: String? = nil,
        proofValue: String? = nil,
        challenge: String? = nil,
        domain: String? = nil,
        nonce: String? = nil,
        raw: AnyCodable? = nil
    ) {
        self.type = type
        self.created = created
        self.verificationMethod = verificationMethod
        self.proofPurpose = proofPurpose
        self.jws = jws
        self.proofValue = proofValue
        self.challenge = challenge
        self.domain = domain
        self.nonce = nonce
        self.raw = raw
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(String.self, forKey: .type)
        self.created = try container.decodeIfPresent(Date.self, forKey: .created)
        self.verificationMethod = try container.decodeIfPresent(String.self, forKey: .verificationMethod)
        self.proofPurpose = try container.decodeIfPresent(String.self, forKey: .proofPurpose)
        self.jws = try container.decodeIfPresent(String.self, forKey: .jws)
        self.proofValue = try container.decodeIfPresent(String.self, forKey: .proofValue)
        self.challenge = try container.decodeIfPresent(String.self, forKey: .challenge)
        self.domain = try container.decodeIfPresent(String.self, forKey: .domain)
        self.nonce = try container.decodeIfPresent(String.self, forKey: .nonce)
        self.raw = try AnyCodable(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        guard let raw else {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.type, forKey: .type)
            try container.encodeIfPresent(self.created, forKey: .created)
            try container.encodeIfPresent(self.verificationMethod, forKey: .verificationMethod)
            try container.encodeIfPresent(self.proofPurpose, forKey: .proofPurpose)
            try container.encodeIfPresent(self.jws, forKey: .jws)
            try container.encodeIfPresent(self.proofValue, forKey: .proofValue)
            try container.encodeIfPresent(self.challenge, forKey: .challenge)
            try container.encodeIfPresent(self.domain, forKey: .domain)
            try container.encodeIfPresent(self.nonce, forKey: .nonce)
            return
        }

        try raw.encode(to: encoder)
    }
}

