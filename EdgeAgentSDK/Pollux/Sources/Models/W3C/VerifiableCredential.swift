import Core
import Domain
import Foundation

/// A convenient, ready‑to‑use alias for a W3C Verifiable Credential with
/// permissive, interoperable default types.
///
/// DefaultVerifiableCredential is a typealias of `VerifiableCredential` that
/// selects broadly compatible “default” representations for each generic
/// parameter. It is ideal when you want to parse, validate, and round‑trip
/// Verifiable Credentials without first defining strongly typed domain models.
///
/// Overview
/// - Supports VCDM 1.0, 1.1, and 2.0 (handles legacy `issuanceDate`/`expirationDate`
///   and modern `validFrom`/`validUntil`, flexible issuer representations, and
///   one‑or‑many semantics).
/// - Uses flexible, JSON‑like containers (`DefaultObject`) for most fields to
///   accept a wide variety of ecosystem payloads.
/// - Allows one‑or‑many values where the ecosystem commonly does (e.g. subject,
///   schema, terms of use, evidence, refresh service, proof) via `OneOrMany`.
/// - Supports issuer as either a DID/URI string or an expanded object with `id`
///   via `IssuerDefaultObject<DefaultIdentifiableObject>`.
/// - Preserves unknown or vendor‑specific fields through the underlying
///   `RawCodable`/`AnyCodable` machinery for reliable round‑tripping.
///
/// Selected default types
/// - IssuerObject: `DefaultIdentifiableObject`
///   - Expanded issuer object with an `id` field; also supports plain string issuer values.
/// - CredentialSubject: `OneOrMany<DefaultObject>`
///   - Accepts either a single subject object or an array of subject objects.
/// - CredentialSchema: `DefaultObject`
///   - Permissive container for schema descriptors (e.g., `id`, `type`, etc.).
/// - CredentialStatus: `DefaultIdentifiableAndTypeObject`
///   - Common status shape with both `id` and `type`.
/// - TermsOfUse: `DefaultObject`
///   - Flexible representation for terms of use entries.
/// - Evidence: `DefaultObject`
///   - Flexible representation for evidence entries.
/// - RefreshService: `DefaultObject`
///   - Flexible representation for refresh service entries.
/// - LinkedDataProof: `DefaultLinkedDataProof`
///   - Common Linked Data Proof structure used by many VC implementations.
///
/// Decoding and encoding behavior
/// - Dates
///   - `validFrom`: Decodes from `validFrom` or legacy `issuanceDate` (required by this model).
///   - `validUntil`: Decodes from `validUntil` or legacy `expirationDate`.
///   - Encoding prefers `validFrom`/`validUntil`.
/// - One‑or‑many fields
///   - `@context`, `credentialSubject`, `credentialSchema`, `termsOfUse`,
///     `evidence`, `refreshService`, and `proof` accept either a single value
///     or an array.
/// - Raw preservation
///   - If the original JSON is available, it is preserved and used for
///     round‑tripping; otherwise fields are re‑encoded from the structured model.
///
/// When to use
/// - Quick integration when credential payloads vary across issuers.
/// - Interoperability testing and ingestion pipelines.
/// - Situations where you want to preserve unknown fields and still access
///   common VC properties in a type‑safe way.
///
/// Customize when needed
/// - If you have a well‑defined domain model (e.g., a strongly typed subject or
///   schema), instantiate `VerifiableCredential` with your own concrete types.
///
/// Conforms to:
/// - `RawCodable`, `Codable`
///
/// See also
/// - `VerifiableCredential`
/// - `IssuerDefaultObject`, `DefaultIdentifiableObject`, `DefaultIdentifiableAndTypeObject`
/// - `DefaultObject`, `OneOrMany`
/// - `DefaultLinkedDataProof`
/// - W3C Verifiable Credentials Data Model 1.0 (2019): https://www.w3.org/TR/2019/REC-vc-data-model-20191119/
/// - W3C Verifiable Credentials Data Model 1.1: https://www.w3.org/TR/vc-data-model-1.1/
/// - W3C Verifiable Credentials Data Model 2.0: https://www.w3.org/TR/vc-data-model-2.0/
public typealias DefaultVerifiableCredential = VerifiableCredential<
    DefaultIdentifiableObject,
    OneOrMany<DefaultObject>,
    DefaultObject,
    DefaultIdentifiableAndTypeObject,
    DefaultObject,
    DefaultObject,
    DefaultObject,
    DefaultLinkedDataProof
>

/// A Verifiable Credential container aligned with the W3C VC Data Model
///
/// `VerifiableCredential` models the core structure of a W3C Verifiable Credential
/// (VC). It supports VC fields and common ecosystem variations while preserving
/// type‑safety and flexible representations used across implementations.
///
/// This model is designed to interoperate across VCDM 1.0, 1.1, and 2.0 by
/// handling legacy field names (e.g., `issuanceDate`/`expirationDate`) alongside
/// modern `validFrom`/`validUntil`, supporting issuer as either a DID/URI string
/// or an expanded object, and allowing one‑or‑many semantics for several fields.
///
/// - Generics:
///   - `IssuerObject`: The expanded issuer object type (must be `Identifiable & RawCodable`).
///     The `issuer` field is represented as `IssuerDefaultObject<IssuerObject>` to support
///     either a DID/URI string or an expanded object with `id`.
///   - `CredentialSubject`: The credentialSubject payload type.
///   - `CredentialSchema`: Schema descriptor(s) associated with the VC.
///   - `CredentialStatus`: Status entry describing revocation/suspension sources.
///   - `TermsOfUse`: Terms of use entries for the VC.
///   - `Evidence`: Evidence entries supporting the VC claims.
///   - `RefreshService`: Refresh service entries for obtaining updated credentials.
///   - `LinkedDataProof`: Proof type used by this VC (often a Linked Data Proof).
///
/// - Notable behavior:
///   - Supports VCDM 1.0, 1.1, and 2.0.
///   - `issuer` may be a DID/URI string or an expanded object (via `IssuerDefaultObject`).
///   - `validFrom` decodes from either `validFrom` or legacy `issuanceDate` and represents
///     the credential's issuance/start time. Encoding uses `validFrom`.
///   - `validUntil` decodes from either `validUntil` or legacy `expirationDate` and represents
///     the credential's expiry. Encoding uses `validUntil`.
///   - Several fields support one-or-many semantics via `OneOrMany<T>` to match the
///     VC ecosystem's flexibility (`@context`, `credentialSchema`, `termsOfUse`, `evidence`,
///     `refreshService`, `proof`).
///
/// - Conforms to:
///   - `RawCodable`, `Codable`
///
/// - See also:
///   - W3C Verifiable Credentials Data Model 1.0 (2019): https://www.w3.org/TR/2019/REC-vc-data-model-20191119/
///   - W3C Verifiable Credentials Data Model 1.1: https://www.w3.org/TR/vc-data-model-1.1/
///   - W3C Verifiable Credentials Data Model 2.0: https://www.w3.org/TR/vc-data-model-2.0/
///   - `IssuerDefaultObject`, `OneOrMany`, `DefaultLinkedDataProof`, `RawCodable`, `Codable`
public struct VerifiableCredential<
    IssuerObject: Identifiable & RawCodable,
    CredentialSubject: RawCodable,
    CredentialSchema: RawCodable,
    CredentialStatus: RawCodable,
    TermsOfUse: RawCodable,
    Evidence: RawCodable,
    RefreshService: RawCodable,
    LinkedDataProof: RawCodable
>: RawCodable {

    public enum CodingKeys: String, CodingKey {
        case context = "@context"
        case id
        case type
        case name
        case description
        case issuer
        case issuanceDate
        case expirationDate
        case validFrom
        case validUntil
        case credentialSubject
        case credentialStatus
        case credentialSchema
        case termsOfUse
        case evidence
        case refreshService
        case proof
        case raw
    }

    /// The JSON-LD `@context` values. Supports one-or-many via `OneOrMany`.
    public var context: OneOrMany<String>
    /// Optional credential identifier (typically a URI).
    public var id: String?
    /// Credential type(s). Includes "VerifiableCredential" and any domain-specific types.
    public var type: [String]
    /// Optional human-readable name/title for the credential.
    public var name: String?
    /// Optional human-readable description of the credential.
    public var description: String?
    /// The issuer as a DID/URI string or an expanded object with `id` (via `IssuerDefaultObject`).
    public var issuer: IssuerDefaultObject<IssuerObject>
    /// Start/issuance time of the credential. Decodes from `validFrom` or legacy `issuanceDate`.
    public var validFrom: Date?
    /// Expiration time of the credential. Decodes from `validUntil` or legacy `expirationDate`.
    public var validUntil: Date?
    /// The credential subject payload describing claims about the subject.
    public var credentialSubject: CredentialSubject
    /// Optional status entry describing revocation/suspension information.
    public var credentialStatus: CredentialStatus?
    /// Optional schema descriptor(s) for the credential. Supports one-or-many.
    public var credentialSchema: OneOrMany<CredentialSchema>?
    /// Optional terms of use entries. Supports one-or-many.
    public var termsOfUse: OneOrMany<TermsOfUse>?
    /// Optional evidence entries supporting the credential. Supports one-or-many.
    public var evidence: OneOrMany<Evidence>?
    /// Optional refresh service entries for obtaining updated credentials. Supports one-or-many.
    public var refreshService: OneOrMany<RefreshService>?
    /// Optional Linked Data Proof(s) attached to the credential. Supports one-or-many.
    public var proof: OneOrMany<LinkedDataProof>?
    public var raw: AnyCodable?

    /// Creates a new Verifiable Credential value.
    ///
    /// - Parameters:
    ///   - context: The JSON-LD `@context` values (one-or-many).
    ///   - id: Optional credential identifier (URI).
    ///   - type: Credential type(s), including "VerifiableCredential" and domain-specific types.
    ///   - name: Optional human-readable name/title.
    ///   - description: Optional human-readable description.
    ///   - issuer: DID/URI or expanded issuer object with `id`.
    ///   - validFrom: Start/issuance time. Decodes from `validFrom` or legacy `issuanceDate`.
    ///   - validUntil: Expiration time. Decodes from `validUntil` or legacy `expirationDate`.
    ///   - credentialSubject: The subject payload containing claims.
    ///   - credentialStatus: Optional status information.
    ///   - credentialSchema: Optional schema descriptor(s) (one-or-many).
    ///   - termsOfUse: Optional terms of use entries (one-or-many).
    ///   - evidence: Optional evidence entries (one-or-many).
    ///   - refreshService: Optional refresh service entries (one-or-many).
    ///   - proof: Optional proof(s) attached to the credential (one-or-many).
    public init(
        context: OneOrMany<String>,
        id: String? = nil,
        type: [String],
        name: String? = nil,
        description: String? = nil,
        issuer: IssuerDefaultObject<IssuerObject>,
        validFrom: Date? = nil,
        validUntil: Date? = nil,
        credentialSubject: CredentialSubject,
        credentialStatus: CredentialStatus? = nil,
        credentialSchema: OneOrMany<CredentialSchema>? = nil,
        termsOfUse: OneOrMany<TermsOfUse>? = nil,
        evidence: OneOrMany<Evidence>? = nil,
        refreshService: OneOrMany<RefreshService>? = nil,
        proof: OneOrMany<LinkedDataProof>? = nil,
        raw: AnyCodable? = nil
    ) {
        self.context = context
        self.id = id
        self.type = type
        self.issuer = issuer
        self.validFrom = validFrom
        self.validUntil = validUntil
        self.credentialSubject = credentialSubject
        self.credentialStatus = credentialStatus
        self.credentialSchema = credentialSchema
        self.termsOfUse = termsOfUse
        self.evidence = evidence
        self.refreshService = refreshService
        self.proof = proof
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.context = try container.decodeIfPresent(OneOrMany<String>.self, forKey: .context) ?? .many([])
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.type = try container.decode([String].self, forKey: .type)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.issuer = try container.decode(IssuerDefaultObject<IssuerObject>.self, forKey: .issuer)
        if let validFrom = try container.decodeIfPresent(Date.self, forKey: .validFrom) {
            self.validFrom = validFrom
        } else if let issuanceDate = try container.decodeIfPresent(Date.self, forKey: .issuanceDate) {
            self.validFrom = issuanceDate
        } else {
            throw DecodingError.keyNotFound(CodingKeys.validFrom, .init(codingPath: [CodingKeys.validFrom], debugDescription: "Key 'validFrom' or 'issuanceDate' does not exist"))
        }
        self.validUntil = try container.decodeIfPresent(Date.self, forKey: .validUntil) ?? container.decodeIfPresent(Date.self, forKey: .expirationDate)
        self.credentialSubject = try container.decode(CredentialSubject.self, forKey: .credentialSubject)
        self.credentialStatus = try container.decodeIfPresent(CredentialStatus.self, forKey: .credentialStatus)
        self.credentialSchema = try container.decodeIfPresent(OneOrMany<CredentialSchema>.self, forKey: .credentialSchema)
        self.termsOfUse = try container.decodeIfPresent(OneOrMany<TermsOfUse>.self, forKey: .termsOfUse)
        self.evidence = try container.decodeIfPresent(OneOrMany<Evidence>.self, forKey: .evidence)
        self.refreshService = try container.decodeIfPresent(OneOrMany<RefreshService>.self, forKey: .refreshService)
        self.proof = try container.decodeIfPresent(OneOrMany<LinkedDataProof>.self, forKey: .proof)
        // Prefer embedded raw if present; otherwise use reconstructed
        self.raw = try AnyCodable(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        guard let raw else {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.context, forKey: .context)
            try container.encodeIfPresent(self.id, forKey: .id)
            try container.encode(self.type, forKey: .type)
            try container.encodeIfPresent(self.name, forKey: .name)
            try container.encodeIfPresent(self.description, forKey: .description)
            try container.encode(self.issuer, forKey: .issuer)
            try container.encodeIfPresent(self.validFrom, forKey: .validFrom)
            try container.encodeIfPresent(self.validUntil, forKey: .validUntil)
            try container.encode(self.credentialSubject, forKey: .credentialSubject)
            try container.encodeIfPresent(self.credentialStatus, forKey: .credentialStatus)
            try container.encodeIfPresent(self.credentialSchema, forKey: .credentialSchema)
            try container.encodeIfPresent(self.termsOfUse, forKey: .termsOfUse)
            try container.encodeIfPresent(self.evidence, forKey: .evidence)
            try container.encodeIfPresent(self.refreshService, forKey: .refreshService)
            try container.encodeIfPresent(self.proof, forKey: .proof)
            return
        }
        try raw.encode(to: encoder)
    }
}

