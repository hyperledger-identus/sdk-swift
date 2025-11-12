# Edge Agent Issue Credential Tutorial

This document explains how to issue W3C Verifiable Credentials using the Edge Agent SDK, supporting both standard JWT-based credentials (`vc+jwt`) and privacy-preserving Selective Disclosure credentials (`vc+sdjwt`). It provides step-by-step examples, expected outputs, and references to relevant W3C and IETF standards.

## Overview

This guide explains how to issue **W3C Verifiable Credentials (VCs)** using your Edge Agent SDK.  
It covers both **JWT-based credentials (`vc+jwt`)** and **Selective Disclosure JWT credentials (`vc+sdjwt`)**, following the [W3C Verifiable Credentials Data Model v2.0](https://www.w3.org/TR/vc-data-model-2.0/) and [IETF SD-JWT specification](https://www.ietf.org/archive/id/draft-ietf-oauth-selective-disclosure-jwt-07.html).

---

## Prerequisites

Before issuing a credential:

1. **DIDs (Decentralized Identifiers)** for both the issuer and the subject must exist.  
   - Example: `did:example:issuer`, `did:example:subject`.
2. The issuer must have a valid **private key** corresponding to the public key referenced in the DID Document.
3. The Edge Agent SDK must be properly initialized and configured with:
   - DID resolver for `DID`
   - Cryptographic signer for JWT
   - Optional: SD-JWT salt generator and hasher

---

## API Summary

```swift
func issueCredential(
    issuerDID: DID,
    type: String, // "vc+jwt" or "vc+sdjwt"
    claims: () -> ClaimBuilder
) throws -> VerifiableCredential
```

### Parameters
| Parameter | Description |
|------------|-------------|
| `issuerDID` | The DID of the entity issuing the credential. |
| `type` | The credential format — `"jwt", "vc+jwt"` or "sdjwt",`"vc+sdjwt"`. |
| `claims` | A closure used to build the VC payload using structured claim builders. |

### Returns
A `Credential` object containing:
- `jwt` or `sdjwt` representation (depending on type)
- Decoded payload as JSON
- Cryptographic proof metadata

---

## Issue a W3C JWT Credential

This example shows how to issue a **Verifiable Credential (JWT)** using the `"vc+jwt"` type.

```swift
let issuerDID = try DID(string: "did:example:issuer")
let subjectDID = try DID(string: "did:example:subject")

edgeAgent.issueCredential(
    issuerDID: issuerDID,
    type: "vc+jwt"
) {
    W3CV2ContextClaim() // Adds "https://www.w3.org/ns/credentials/v2"
    W3CIssuerClaim(id: issuerDID.string)
    W3CTypeClaim()
    StringClaim(key: "name", value: "University Degree")
    W3CCredentialSubjectClaim(subject: {
        StringClaim(key: "id", value: subjectDID.string)
        StringClaim(key: "name", value: "John Doe")
        ObjectClaim(key: "grades") {
            NumberClaim(key: "mathematic", value: 8)
            NumberClaim(key: "physics", value: 7.2)
            NumberClaim(key: "english", value: 9.9)
        }
        BoolClaim(key: "approved", value: true)
        ArrayClaim(key: "professors") {
            ArrayValueClaim.string("Professor Jane Doe")
            ArrayValueClaim.string("Professor Josef Doe")
        }
    })
}
```

### Example Output

**JWT Token:**
```
eyJhbGciOiJFUzI1NksifQ.eyJAY29udGV4dCI6WyJodHRwczovL3d3dy53My5vcmcvbnMvY3JlZGVudGlhbHMvdjIiXSwiY3JlZGVudGlhbFN1YmplY3QiOnsiYXBwcm92ZWQiOnRydWUsImdyYWRlcyI6eyJlbmdsaXNoIjo5LjksIm1hdGhlbWF0aWMiOjgsInBoeXNpY3MiOjcuMn0sImlkIjoiZGlkOmV4YW1wbGU6c3ViamVjdCIsIm5hbWUiOiJKb2huIERvZSIsInByb2Zlc3NvcnMiOlsiUHJvZmVzc29yIEphbmUgRG9lIiwiUHJvZmVzc29yIEpvc2VmIERvZSJdfSwiaXNzdWVyIjoiZGlkOmV4YW1wbGU6aXNzdWVyIiwibmFtZSI6IlVuaXZlcnNpdHkgRGVncmVlIiwidHlwZSI6WyJWZXJpZmlhYmxlQ3JlZGVudGlhbCJdfQ.JYw5aTJrEvXuTKIsM0vJbezd_7Pc_eBvrMSWF9tPQB2gRv083DAVtnDe9-gYavUANx6bD3rtCGqWEWO-M0cjag
```

**Decoded Payload:**
```json
{
  "@context": ["https://www.w3.org/ns/credentials/v2"],
  "credentialSubject": {
    "approved": true,
    "grades": {
      "english": 9.9,
      "mathematic": 8,
      "physics": 7.2
    },
    "id": "did:example:subject",
    "name": "John Doe",
    "professors": [
      "Professor Jane Doe",
      "Professor Josef Doe"
    ]
  },
  "issuer": "did:example:issuer",
  "name": "University Degree",
  "type": ["VerifiableCredential"]
}
```

---

## Issue a SD-JWT W3C Credential

This example issues a **Selective Disclosure Verifiable Credential** (`vc+sdjwt`), where certain fields are marked as _disclosable_.  
These fields can be selectively revealed by the holder when presenting the credential.

```swift
let issuerDID = try DID(string: "did:example:issuer")
let subjectDID = try DID(string: "did:example:subject")

edgeAgent.issueCredential(
    issuerDID: issuerDID,
    type: "vc+sdjwt"
) {
    W3CV2ContextClaim()
    W3CIssuerClaim(id: issuerDID.string)
    W3CTypeClaim()
    StringClaim(key: "name", value: "University Degree")
    W3CCredentialSubjectClaim(subject: {
        StringClaim(key: "id", value: subjectDID.string)
        StringClaim(key: "name", value: "John Doe", disclosable: true)
        ObjectClaim(key: "grades", disclosable: true) {
            NumberClaim(key: "mathematic", value: 8)
            NumberClaim(key: "physics", value: 7.2)
            NumberClaim(key: "english", value: 9.9)
        }
        BoolClaim(key: "approved", value: true, disclosable: true)
        ArrayClaim(key: "professors", disclosable: true) {
            ArrayValueClaim.string("Professor Jane Doe")
            ArrayValueClaim.string("Professor Josef Doe")
        }
    })
}
```

### Example Output

**SD-JWT Token:**
```
eyJhbGciOiJFUzI1NksifQ.eyIiOnsidHlwZSI6WyJWZXJpZmlhYmxlQ3JlZGVudGlhbCJdLCJpc3N1ZXIiOiJkaWQ6ZXhhbXBsZTppc3N1ZXIiLCJuYW1lIjoiVW5pdmVyc2l0eSBEZWdyZWUiLCJAY29udGV4dCI6WyJodHRwczpcL1wvd3d3LnczLm9yZ1wvbnNcL2NyZWRlbnRpYWxzXC92MiJdLCJjcmVkZW50aWFsU3ViamVjdCI6eyJfc2QiOlsiOWVlYU95VFUzQUVKMnZkdHk5MnJmZ2JLdmFIQ2ZWLUtKUm01NlI0RlVvTSIsIm1JNmlVLVVDcU1VdFF5UFJUXzY1UktNZ2lPZjZJZ1YxTU1xYkJPQVVxbFEiLCJ5RUozX2JiQzlOdzVycXlLNWsxRklGUUFKcDAwVTZWWXhCZ1NwWDlyaHhFIiwiZkpncnpJZnd0ejE2ekpEczYyYjl1OENxYzMxNlhHVVhLYkdHV0Rsb0FWcyJdLCJpZCI6ImRpZDpleGFtcGxlOnN1YmplY3QifX0sIl9zZF9hbGciOiJzaGEtMjU2In0.3Zg3tQnTXOy_apKw14yrzYynIOH-mJMZ3Wi6Lod-0oWRMDq7aAVpoB5Jj_4u6tyGF6kzQ2iZG8DgKqveWeXSCw~...
```

**Hashed Payload (issued credential):**
```json
{
  "": {
    "type": ["VerifiableCredential"],
    "issuer": "did:example:issuer",
    "name": "University Degree",
    "@context": ["https://www.w3.org/ns/credentials/v2"],
    "credentialSubject": {
      "_sd": [
        "9eeaOyTU3AEJ2vdty92rfgbKvaHCfV-KJRm56R4FUoM",
        "mI6iU-UCqMUtQyPRT_65RKMgiOf6IgV1MMqbBOAUqlQ",
        "yEJ3_bbC9Nw5rqyK5k1FIFQAJp00U6VYxBgSpX9rhxE",
        "fJgrzIfwtz16zJDs62b9u8Cqc316XGUXKbGGWDloAVs"
      ],
      "id": "did:example:subject"
    }
  },
  "_sd_alg": "sha-256"
}
```

**Disclosed Payload (after holder reveals claims):**
```json
{
  "": {
    "type": ["VerifiableCredential"],
    "issuer": "did:example:issuer",
    "name": "University Degree",
    "@context": ["https://www.w3.org/ns/credentials/v2"],
    "credentialSubject": {
      "id": "did:example:subject",
      "name": "John Doe",
      "approved": true,
      "grades": {
        "mathematic": 8,
        "physics": 7.2,
        "english": 9.9
      },
      "professors": [
        "Professor Jane Doe",
        "Professor Josef Doe"
      ]
    }
  }
}
```

---

## Claim Builders Reference

| Claim | Description |
|--------|--------------|
| `W3CV2ContextClaim()` | Adds the default W3C v2 context. |
| `W3CIssuerClaim(id:)` | Defines the issuer DID. |
| `W3CTypeClaim()` | Adds `"VerifiableCredential"` to `type`. |
| `W3CCredentialSubjectClaim(subject:)` | Starts the credential subject block. |
| `StringClaim(key:value:disclosable:)` | Adds a string claim. |
| `NumberClaim(key:value:disclosable:)` | Adds a numeric claim. |
| `BoolClaim(key:value:disclosable:)` | Adds a boolean claim. |
| `ObjectClaim(key:disclosable:content:)` | Adds a nested JSON object. |
| `ArrayClaim(key:disclosable:content:)` | Adds an array of values. |

> Note: The `disclosable` parameter only applies when using `vc+sdjwt`. It is ignored for `vc+jwt`.

---

## Best Practices

- Always use **DIDs with valid cryptographic proofs** and ensure the DID document can be resolved.
- When issuing SD-JWTs, avoid marking sensitive claims as disclosable unless necessary.
- Store only **hashed salts** for SD-JWT claims server-side — never store cleartext values.
- Use short expiration times for test credentials and refresh regularly.

---

## Related Standards

- [W3C Verifiable Credentials Data Model v2.0](https://www.w3.org/TR/vc-data-model-2.0/)
- [IETF SD-JWT (Selective Disclosure JWT)](https://www.ietf.org/archive/id/draft-ietf-oauth-selective-disclosure-jwt-07.html)
- [DID Core Specification](https://www.w3.org/TR/did-core/)
- [JOSE / JWT RFC7519](https://www.rfc-editor.org/rfc/rfc7519)
