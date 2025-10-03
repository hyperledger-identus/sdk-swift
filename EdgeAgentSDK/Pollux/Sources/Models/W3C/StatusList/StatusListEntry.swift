import Core
import Foundation

/// A reference to a status list entry associated with a verifiable credential.
///
/// StatusListEntry models the value commonly found in a credential’s
/// `credentialStatus` field when the credential participates in a W3C Status List,
/// such as Status List 2021 or Bitstring Status List. It tells verifiers:
/// - which status list credential to fetch (`statusListCredential`)
/// - which bit (or window of bits) in that list pertains to this credential (`statusListIndex`, `statusSize`)
/// - how to interpret that bit/window (`statusPurpose`)
///
/// The struct is intentionally permissive so it can interoperate across ecosystems
/// and evolving specifications. It preserves unknown or vendor‑specific fields for
/// lossless round‑tripping via `RawCodable`.
///
/// Key concepts
/// - Status list credential: A separate verifiable credential that carries a compressed/encoded bitstring
///   representing statuses for many credentials.
/// - Index/Window: Each subject credential references a bit (or a window of bits) in that list.
/// - Purpose: How the referenced bit/window should be interpreted (e.g., revocation, suspension).
///
/// Specification alignment
/// - W3C Verifiable Credentials Data Model 1.1: https://www.w3.org/TR/vc-data-model-1.1/
/// - W3C Verifiable Credentials Data Model 2.0: https://www.w3.org/TR/vc-data-model-2.0/
/// - W3C Status List 2021: https://www.w3.org/TR/vc-status-list-2021/
/// - W3C Bitstring Status List: https://www.w3.org/TR/vc-bitstring-status-list/
///
/// Properties
/// - `id`: Identifier for this status entry (often a URI or a fragment inside the credential).
/// - `type`: Status entry type as a string (e.g., "StatusList2021Entry", "BitstringStatusListEntry").
///   A helper enum `CredentialStatusListType` lists known values, but `type` remains a `String`
///   for better interoperability.
/// - `statusPurpose`: Purpose of the status indication (e.g., `.revocation`, `.suspension`, `.refresh`, `.message`).
/// - `statusListIndex`: Index in the status list that corresponds to this credential. This is used to locate
///   the relevant bit (or window) in the encoded list.
/// - `statusListCredential`: URI of the status list verifiable credential document to fetch and decode.
/// - `statusSize`: Size of the status window (defaults to 1 for single‑bit semantics). Some ecosystems may use
///   multi‑bit windows for richer semantics.
/// - `statusMessage`: Optional human‑readable messages (suite/vendor‑specific). Helpful for `.message` purpose
///   or user feedback.
/// - `raw`: The original JSON payload preserved for round‑tripping via `RawCodable`.
///
/// Decoding/encoding behavior
/// - Decoding:
///   - `statusSize` defaults to `1` if absent.
///   - All declared fields are decoded from their corresponding keys.
///   - Unknown fields are preserved in `raw` to support lossless round‑tripping.
/// - Encoding:
///   - If `raw` is present, it is emitted verbatim to maintain original payload fidelity.
///   - Otherwise, the declared properties are encoded normally.
///
/// Typical flow
/// 1. A verifiable credential under verification contains `credentialStatus` modeled by `StatusListEntry`.
/// 2. Use `statusListCredential` to resolve the status list credential (see `StatusListCredential`).
/// 3. Decode the list and inspect its `encodedList`.
/// 4. Examine the bit (or window) at `statusListIndex` (respecting `statusSize` if > 1).
/// 5. Interpret the result according to `statusPurpose` (e.g., if the bit is set for revocation, the credential is revoked).
///
/// Example JSON (illustrative)
/// ```json
/// {
///   "id": "https://example.org/credentials/123#status",
///   "type": "StatusList2021Entry",
///   "statusPurpose": "revocation",
///   "statusListIndex": 42,
///   "statusListCredential": "https://example.org/status/2021/credentials.json",
///   "statusSize": 1,
///   "statusMessage": [ { "status": "revoked", "message": "Credential has been revoked." } ]
/// }
/// ```
///
/// Notes
/// - Index base and bit semantics are defined by the status list format and implementation. Consult the
///   relevant specification or library for decoding and bit/window interpretation.
/// - `type` is intentionally a `String` to allow future or vendor‑specific values beyond the known set.
///
/// See also
/// - `StatusListCredential`: A ready‑to‑use `VerifiableCredential` specialization for status lists.
/// - `StatusListCredentialSubject`: The subject payload that carries the encoded bitstring.
/// - `VerifiableCredential`: Generic container for VC data models.
/// - `RawCodable`, `AnyCodable`: For preserving unknown fields during decode/encode.
/// - `CredentialStatusListType`, `CredentialStatusPurpose`: Helper enums for known values.
public struct StatusListEntry: RawCodable {
    /// Known status list entry types as used by W3C status list specifications.
    public enum CredentialStatusListType: String, Codable {
        case statusList2021Entry = "StatusList2021Entry"
        case bitString = "BitstringStatusListEntry"
    }

    /// Purpose for which the status bit is maintained (e.g., revocation or suspension).
    public enum CredentialStatusPurpose: String, Codable {
        case revocation = "revocation"
        case suspension = "suspension"
        case refresh = "refresh"
        case message = "message"
    }

    public enum CodingKeys: CodingKey {
        case id
        case type
        case statusPurpose
        case statusListIndex
        case statusListCredential
        case statusSize
        case statusMessage
    }

    public struct Message: Codable {
        let status: String
        let message: String
    }

    /// Identifier for this status entry (typically a URI fragment within the credential).
    public let id: String
    /// The status entry type (e.g., `StatusList2021Entry` or `BitstringStatusListEntry`).
    public let type: String
    /// The purpose of the status bit (revocation, suspension, etc.).
    public let statusPurpose: CredentialStatusPurpose
    /// The index in the status list (bit position) associated with this credential.
    public let statusListIndex: Int
    /// URI of the status list credential that carries the encoded bitstring.
    public let statusListCredential: String
    /// Size of the status entry window (defaults to 1 for single‑bit semantics).
    public let statusSize: Int
    /// Optional human‑readable messages describing the status (suite/vendor‑specific).
    public let statusMessage: [Message]?
    public let raw: AnyCodable?

    /// Creates a new status list entry reference.
    ///
    /// - Parameters:
    ///   - id: Identifier for the status entry (typically a URI/fragment).
    ///   - type: The status entry type (e.g., `StatusList2021Entry`).
    ///   - statusPurpose: Purpose of the status bit (revocation, suspension, etc.).
    ///   - statusListIndex: Index in the status list associated with this credential.
    ///   - statusListCredential: URI of the status list credential document.
    ///   - statusSize: Size of the status entry window (defaults to 1).
    ///   - statusMessage: Optional human‑readable messages for this status.
    public init(
        id: String,
        type: String,
        statusPurpose: CredentialStatusPurpose,
        statusListIndex: Int,
        statusListCredential: String,
        statusSize: Int = 1,
        statusMessage: [Message]?,
        raw: AnyCodable? = nil
    ) {
        self.id = id
        self.type = type
        self.statusPurpose = statusPurpose
        self.statusListIndex = statusListIndex
        self.statusListCredential = statusListCredential
        self.statusSize = statusSize
        self.statusMessage = statusMessage
        self.raw = raw
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.type = try container.decode(String.self, forKey: .type)
        self.statusPurpose = try container.decode(StatusListEntry.CredentialStatusPurpose.self, forKey: .statusPurpose)
        self.statusListIndex = try container.decode(Int.self, forKey: .statusListIndex)
        self.statusListCredential = try container.decode(String.self, forKey: .statusListCredential)
        self.statusSize = try container.decodeIfPresent(Int.self, forKey: .statusSize) ?? 1
        self.statusMessage = try container.decodeIfPresent([Message].self, forKey: .statusMessage)
        self.raw = try AnyCodable(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        guard let raw else {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.id, forKey: .id)
            try container.encode(self.type, forKey: .type)
            try container.encode(self.statusPurpose, forKey: .statusPurpose)
            try container.encode(self.statusListIndex, forKey: .statusListIndex)
            try container.encode(self.statusListCredential, forKey: .statusListCredential)
            try container.encode(self.statusSize, forKey: .statusSize)
            try container.encodeIfPresent(self.statusMessage, forKey: .statusMessage)
            return
        }
        try raw.encode(to: encoder)
    }
}

/// A credential subject that carries a compressed/encoded status bitstring for a W3C Status List.
///
/// StatusListCredentialSubject models the payload inside a dedicated “status list” verifiable credential
/// (e.g., Status List 2021 or Bitstring Status List). Other credentials reference a specific position (bit
/// or window) within this list via their `credentialStatus` entry (see `StatusListEntry`). Verifiers decode
/// the list and inspect the referenced bit(s) to determine revocation, suspension, or other status.
///
/// What it represents
/// - A single status list document (the “list VC”) whose subject provides:
///   - An identifier for the list (`id`)
///   - A subject type (`type`, e.g., "StatusList2021" or "BitstringStatusList")
///   - The purpose of the bits in the list (`statusPurpose`, e.g., `.revocation`, `.suspension`)
///   - The compressed/encoded bitstring (`encodedList`)
///   - A reference or partition identifier within the list (`statusReference`)
///
/// Relationship to `StatusListEntry`
/// - A subject credential (the one being verified) typically contains a `credentialStatus` modeled by
///   `StatusListEntry`. That entry points to this status list credential and an index (`statusListIndex`).
/// - The `statusPurpose` in the list subject should match the purpose declared by the referencing entry.
/// - Verifiers fetch the list VC, decode its subject’s `encodedList`, then check the bit(s) at the index.
///
/// Properties
/// - id: Identifier for the status list subject (commonly the list VC’s URI).
/// - type: Subject type string (e.g., "StatusList2021", "BitstringStatusList").
/// - statusPurpose: The meaning of bits in this list (revocation, suspension, etc.).
/// - encodedList: The compressed/encoded bitstring representing many credentials’ statuses.
///   - Status List 2021 typically uses GZIP + base64url on a bitstring.
///   - Bitstring Status List may use alternative encodings (e.g., CBOR-based).
///   - This type does not perform decoding; integrate a compatible decoder for your format.
/// - statusReference: A reference/partition identifier for the list (suite- or ecosystem-specific).
///   - Helps distinguish lists or partitions (e.g., different purposes, shards, or ranges).
/// - raw: Preserves the original JSON for unknown/vendor-specific fields via `RawCodable`.
///
/// Decoding/encoding behavior
/// - Decoding:
///   - Reads the declared fields (`id`, `type`, `statusPurpose`, `encodedList`, `statusReference`).
///   - Preserves unknown fields into `raw` for lossless round-tripping.
/// - Encoding:
///   - If `raw` is present, it is emitted verbatim to maintain original payload fidelity.
///   - Otherwise, the declared fields are encoded normally.
///
/// Typical verification flow
/// 1. Parse a subject credential’s `credentialStatus` as `StatusListEntry`.
/// 2. Resolve the referenced status list credential (alias: `StatusListCredential`) and read its subject:
///    `StatusListCredential.credentialSubject` (this type).
/// 3. Decode `encodedList` with an implementation compatible with your status list format.
/// 4. Check the bit (or window) at the `statusListIndex` from the `StatusListEntry`.
/// 5. Interpret the result according to `statusPurpose` (e.g., bit set means revoked).
///
/// Example (illustrative JSON)
/// ```json
/// {
///   "id": "https://example.org/status/2021/credentials.json",
///   "type": "StatusList2021",
///   "statusPurpose": "revocation",
///   "encodedList": "H4sIAAAAA...base64url...",
///   "statusReference": "revocation#list"
/// }
/// ```
///
/// Notes
/// - Ensure your JSON encoder/decoder configuration (e.g., date strategies) matches your ecosystem,
///   though this subject type does not include dates itself.
/// - The actual bitstring decompression/decoding is out of scope for this model; use a library that
///   supports Status List 2021 or Bitstring Status List as needed.
/// - `statusReference` is intentionally flexible to accommodate multiple ecosystems.
///
/// See also
/// - StatusListEntry: The `credentialStatus` reference used by subject credentials.
/// - StatusListCredential: A `VerifiableCredential` specialization whose subject is this type.
/// - W3C Status List 2021: https://www.w3.org/TR/vc-status-list-2021/
/// - W3C Bitstring Status List: https://www.w3.org/TR/vc-bitstring-status-list/
/// - W3C Verifiable Credentials Data Model 1.1/2.0
public struct StatusListCredentialSubject: RawCodable {

    public enum CodingKeys: CodingKey {
        case id
        case type
        case statusPurpose
        case encodedList
        case statusReference
    }

    /// Identifier for the status list subject (typically a URI for the list document).
    public let id: String
    /// The subject type (e.g., `StatusList2021` or `BitstringStatusList`).
    public let type: String
    /// The purpose of the status bits in this list (revocation, suspension, etc.).
    public let statusPurpose: StatusListEntry.CredentialStatusPurpose
    /// The compressed/encoded bitstring representing status values for a range of credentials.
    public let encodedList: String
    /// A reference or URI that identifies the specific list or partition within the status list.
    public let statusReference: String
    public let raw: AnyCodable?

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.type = try container.decode(String.self, forKey: .type)
        self.statusPurpose = try container.decode(StatusListEntry.CredentialStatusPurpose.self, forKey: .statusPurpose)
        self.encodedList = try container.decode(String.self, forKey: .encodedList)
        self.statusReference = try container.decode(String.self, forKey: .statusReference)
        self.raw = try AnyCodable(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        guard let raw else {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.id, forKey: .id)
            try container.encode(self.type, forKey: .type)
            try container.encode(self.statusPurpose, forKey: .statusPurpose)
            try container.encode(self.encodedList, forKey: .encodedList)
            try container.encode(self.statusReference, forKey: .statusReference)
            return
        }

        try raw.encode(to: encoder)
    }
}

/// A ready-to-use Verifiable Credential type for W3C Status Lists (Status List 2021 / Bitstring Status List).
///
/// StatusListCredential is a typealias of `VerifiableCredential` specialized for credentials
/// that publish revocation/suspension bitstrings used by other credentials via `credentialStatus`
/// references. It is the credential you fetch using the `statusListCredential` URI found in a
/// `StatusListEntry`, and whose `credentialSubject` contains the compressed/encoded status list.
///
/// Specialization
/// - `IssuerObject`: `DefaultIdentifiableObject`
///   - Permissive issuer representation (supports DID/URI string or expanded object with `id`).
/// - `CredentialSubject`: `StatusListCredentialSubject`
///   - The subject payload for a status list. Includes:
///     - `id`: Identifier for the list (typically a URI).
///     - `type`: Subject type (e.g., "StatusList2021", "BitstringStatusList").
///     - `statusPurpose`: Purpose of bits (e.g., `revocation`, `suspension`).
///     - `encodedList`: The compressed/encoded bitstring.
///     - `statusReference`: A reference/partition identifier for the list.
/// - `CredentialSchema`: `DefaultObject`
///   - Flexible container for schema descriptors.
/// - `CredentialStatus`: `DefaultIdentifiableAndTypeObject`
///   - Common shape with both `id` and `type` when a status object is present on the status list VC itself.
/// - `TermsOfUse`: `DefaultObject`
/// - `Evidence`: `DefaultObject`
/// - `RefreshService`: `DefaultObject`
/// - `LinkedDataProof`: `DefaultLinkedDataProof`
///   - Common Linked Data Proof container.
///
/// Typical flow
/// 1. A credential under verification contains a `credentialStatus` entry modeled by `StatusListEntry`.
/// 2. That entry points to a status list credential via `statusListCredential` (URI) and an index (`statusListIndex`).
/// 3. Resolve and decode the status list credential as `StatusListCredential`.
/// 4. Inspect `credentialSubject.encodedList` (and optional windowing semantics such as `statusSize`)
///    to determine the bit value at the index, interpreting it according to `statusPurpose`.
///
/// Decoding and encoding behavior (inherited from `VerifiableCredential`)
/// - Supports VCDM 1.0, 1.1, and 2.0 date conventions:
///   - `validFrom` decodes from `validFrom` or legacy `issuanceDate` (required by this model).
///   - `validUntil` decodes from `validUntil` or legacy `expirationDate`.
/// - One-or-many semantics via `OneOrMany` for common array-or-singleton fields
///   (e.g., `@context`, `credentialSchema`, `termsOfUse`, `evidence`, `refreshService`, `proof`).
/// - Raw preservation:
///   - Unknown or vendor-specific fields are preserved via `RawCodable`/`AnyCodable` for lossless round‑tripping.
///   - If `raw` is present during encoding, it is emitted verbatim.
///
/// When to use
/// - To ingest and verify W3C Status List credentials referenced by other VCs’ `credentialStatus`.
/// - In interoperability pipelines where status list formats may vary and unknown fields must be preserved.
/// - When you need a pragmatic, flexible model with minimal assumptions about issuer, schema, and proof shapes.
///
/// Usage example
/// ```swift
/// // 1) Decode the status list credential
/// let statusListVC = try JSONDecoder().decode(StatusListCredential.self, from: data)
///
/// // 2) Access the encoded bitstring and purpose
/// let subject = statusListVC.credentialSubject
/// let purpose = subject.statusPurpose         // .revocation, .suspension, etc.
/// let encoded = subject.encodedList           // compressed/encoded bitstring
///
/// // 3) Use alongside a StatusListEntry to interpret a specific bit
/// // (Bitstring decoding and bit-checking are out of scope for this type.)
/// ```
///
/// Notes
/// - Ensure `JSONDecoder`/`JSONEncoder` use appropriate date strategies (e.g., ISO‑8601) consistent with your ecosystem.
/// - This alias does not implement bitstring decompression or bit checking; integrate a compatible decoder for
///   Status List 2021 or Bitstring Status List as needed.
///
/// Conforms to
/// - `RawCodable`, `Codable` (via `VerifiableCredential`)
///
/// See also
/// - `StatusListEntry` (credentialStatus reference used by subject credentials)
/// - `StatusListCredentialSubject` (payload carrying the encoded list)
/// - `VerifiableCredential` (generic container and behavior)
/// - `DefaultLinkedDataProof`
/// - W3C Verifiable Credentials Data Model 1.1: https://www.w3.org/TR/vc-data-model-1.1/
/// - W3C Verifiable Credentials Data Model 2.0: https://www.w3.org/TR/vc-data-model-2.0/
/// - W3C Status List 2021: https://www.w3.org/TR/vc-status-list-2021/
/// - W3C Bitstring Status List: https://www.w3.org/TR/vc-bitstring-status-list/
public typealias StatusListCredential = VerifiableCredential<
    DefaultIdentifiableObject,
    StatusListCredentialSubject,
    DefaultObject,
    DefaultIdentifiableAndTypeObject,
    DefaultObject,
    DefaultObject,
    DefaultObject,
    DefaultLinkedDataProof
>
