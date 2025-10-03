/// A namespace of canonical identifiers registered by the W3C Verifiable Credentials family of specifications.
///
/// This enum exposes string constants for:
/// - JSON‑LD context URIs that identify the Verifiable Credentials (VC) vocabulary (v1.0 and v2.0)
/// - Well‑known type names used in the `type` array of Verifiable Credentials and Verifiable Presentations
/// - The `EnvelopedVerifiableCredential` type used when a credential is represented in a JOSE/COSE envelope
///
/// Why use these constants:
/// - Prevent typos in critical identifiers that affect interoperability
/// - Make intent explicit and code self‑documenting
/// - Centralize updates if the specifications evolve
///
/// Notes on JSON‑LD contexts:
/// - A JSON‑LD context URI identifies a vocabulary; software does not need to fetch it at runtime to be compliant.
/// - In production environments, avoid network fetching of contexts; ship local, integrity‑checked copies if expansion is required.
///
/// Version guidance:
/// - Prefer the VC Data Model 2.0 context for new implementations.
/// - Use the 1.0 context only when interoperating with legacy systems that require it.
///
/// References:
/// - VC Data Model 2.0: https://www.w3.org/TR/vc-data-model-2.0/
/// - VC Data Model 1.x: https://www.w3.org/TR/vc-data-model/
/// - VC JOSE/COSE: https://www.w3.org/TR/vc-jose-cose/
///
/// Example (credential):
/// ```json
/// {
///   "@context": [ "https://www.w3.org/ns/credentials/v2" ],
///   "type": [ "VerifiableCredential" ],
///   "issuer": "did:example:123",
///   "credentialSubject": { "id": "did:example:abc" }
/// }
/// ```
///
/// Example (presentation):
/// ```json
/// {
///   "@context": [ "https://www.w3.org/ns/credentials/v2" ],
///   "type": [ "VerifiablePresentation" ],
///   "verifiableCredential": [ /* ... */ ]
/// }
/// ```
///
/// Example (enveloped VC, per VC JOSE/COSE):
/// ```json
/// {
///   "@context": [ "https://www.w3.org/ns/credentials/v2" ],
///   "type": [ "EnvelopedVerifiableCredential" ],
///   "credential": "eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9..." // JWS/JWE/COSE
/// }
/// ```
///
/// - Important: These are stable, standardized identifiers. Do not modify their values.
///
/// - SeeAlso: `verifiableCredential1_0Context`, `verifiableCredential2_0Context`,
///            `verifiableCredentialType`, `verifiablePresentationType`,
///            `envelopedVerifiableCredentialType`
///
///
/// The canonical JSON‑LD context URI for the Verifiable Credentials Data Model 1.0/1.1 vocabulary.
/// - Specification: https://www.w3.org/TR/vc-data-model/
/// - Typical usage: The first entry in a VC/VP `@context` array when interoperating with 1.x systems.
///
///
/// The canonical JSON‑LD context URI for the Verifiable Credentials Data Model 2.0 vocabulary.
/// - Specification: https://www.w3.org/TR/vc-data-model-2.0/
/// - Typical usage: The first entry in a VC/VP `@context` array for modern deployments.
///
///
/// The well‑known type name for a Verifiable Credential object.
/// - Appears in the `type` array of credential documents.
/// - Example: `"type": ["VerifiableCredential", "UniversityDegreeCredential"]`
///
///
/// The well‑known type name for a Verifiable Presentation object.
/// - Appears in the `type` array of presentation documents.
/// - Example: `"type": ["VerifiablePresentation"]`
///
///
/// The type name for a credential represented as a JOSE/COSE envelope.
/// - Specification: VC JOSE/COSE — https://www.w3.org/TR/vc-jose-cose/
/// - Typical usage: When the VC payload is embedded as a JWS/JWE/COSE structure instead of a plain JSON‑LD object.
public enum W3CRegisteredConstants {
    public static let verifiableCredential1_0Context = "https://www.w3.org/2018/credentials/v1"
    public static let verifiableCredential2_0Context = "https://www.w3.org/ns/credentials/v2"
    public static let verifiableCredentialType = "VerifiableCredential"
    public static let verifiablePresentationType = "VerifiablePresentation"
    public static let envelopedVerifiableCredentialType = "EnvelopedVerifiableCredential"
}
