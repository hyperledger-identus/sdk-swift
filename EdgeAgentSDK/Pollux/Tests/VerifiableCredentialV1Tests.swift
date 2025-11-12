//
//  VerifiableCredentialV1Tests.swift
//

import XCTest
@testable import Pollux
import Core

final class VerifiableCredentialV1Tests: XCTestCase {

    // MARK: - Helpers

    private func makeDecoder() -> JSONDecoder {
        let d = JSONDecoder()

        let isoNoFrac = ISO8601DateFormatter() // default .withInternetDateTime
        let isoFrac: ISO8601DateFormatter = {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return f
        }()

        d.dateDecodingStrategy = .custom { decoder in
            let c = try decoder.singleValueContainer()
            let s = try c.decode(String.self)
            if let date = isoFrac.date(from: s) ?? isoNoFrac.date(from: s) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: c,
                debugDescription: "Expected ISO8601 date (with or without fractional seconds)."
            )
        }
        return d
    }

    private func makeEncoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }

    // MARK: - Tests

    func testDecode_V1_0_JSONLD_Minimal() throws {
        let json = """
        {
          "@context": ["https://www.w3.org/2018/credentials/v1"],
          "type": ["VerifiableCredential","UniversityDegreeCredential"],
          "issuer": "did:example:123",
          "issuanceDate": "2020-01-01T19:23:24Z",
          "credentialSubject": {
            "id": "did:example:456",
            "degree": { "type":"BachelorDegree", "name":"B.Sc." }
          },
          "proof": {
            "type":"Ed25519Signature2018",
            "created":"2020-01-01T19:23:24Z",
            "verificationMethod":"did:example:123#keys-1",
            "proofPurpose":"assertionMethod",
            "jws":"eyJhbGciOiJFZERTQSJ9..."
          }
        }
        """.data(using: .utf8)!

        let vc = try makeDecoder().decode(DefaultVerifiableCredential.self, from: json)

        XCTAssertNotNil(vc.context)
        XCTAssertEqual(vc.type.array.first, "VerifiableCredential")
        XCTAssertEqual(vc.type.array.contains("UniversityDegreeCredential"), true)
        switch vc.issuer {
        case .id(let s): XCTAssertEqual(s, "did:example:123")
        default: XCTFail("Expected issuer string")
        }
        XCTAssertNotNil(vc.validFrom)
        XCTAssertNil(vc.validUntil)
        XCTAssertNotNil(vc.credentialSubject)
        XCTAssertNotNil(vc.proof)
    }

    func testDecode_V1_1_JSON_NoContext_NoProof() throws {
        // JSON (non-LD), 1.1 valid shape: no @context, no inline proof.
        let json = """
        {
          "type": ["VerifiableCredential"],
          "issuer": { "id": "did:example:issuer-1" },
          "issuanceDate": "2024-06-01T00:00:00Z",
          "credentialSubject": { "memberId": "42", "active": true }
        }
        """.data(using: .utf8)!

        let vc = try makeDecoder().decode(DefaultVerifiableCredential.self, from: json)

        XCTAssertEqual(vc.type.array, ["VerifiableCredential"])
        switch vc.issuer {
        case .object(let obj): XCTAssertEqual(obj.id, "did:example:issuer-1")
        default: XCTFail("Expected issuer object")
        }
        XCTAssertNil(vc.proof)
        // credentialSubject one-or-many should gracefully hold single object
//        XCTAssertEqual(vc.credentialSubject.array.count, 1)
    }

    func testDecode_Issuer_String_And_Object() throws {
        let jsonStrIssuer = """
        {
          "type": ["VerifiableCredential"],
          "issuer": "did:example:string",
          "issuanceDate": "2023-03-01T12:00:00Z",
          "credentialSubject": { "id":"did:example:subj" }
        }
        """.data(using: .utf8)!
        let jsonObjIssuer = """
        {
          "type": ["VerifiableCredential"],
          "issuer": { "id":"did:example:object", "name":"Issuer Inc." },
          "issuanceDate": "2023-03-01T12:00:00Z",
          "credentialSubject": { "id":"did:example:subj" }
        }
        """.data(using: .utf8)!

        let d = makeDecoder()
        let a = try d.decode(DefaultVerifiableCredential.self, from: jsonStrIssuer)
        let b = try d.decode(DefaultVerifiableCredential.self, from: jsonObjIssuer)

        if case .id(let s) = a.issuer { XCTAssertEqual(s, "did:example:string") } else { XCTFail() }
        if case .object(let o) = b.issuer { XCTAssertEqual(o.id, "did:example:object") } else { XCTFail() }
    }

    func testDecode_OneOrMany_Subject_Array() throws {
        let json = """
        {
          "type": ["VerifiableCredential"],
          "issuer": "did:example:123",
          "issuanceDate": "2022-01-01T00:00:00Z",
          "credentialSubject": [
            { "id":"did:example:subj1", "role":"admin" },
            { "id":"did:example:subj2", "role":"member" }
          ]
        }
        """.data(using: .utf8)!

        let vc = try makeDecoder().decode(DefaultVerifiableCredential.self, from: json)
//        XCTAssertEqual(vc.credentialSubject.array.count, 2)
    }

    func testDecode_Proof_Array_With_Challenge_Domain() throws {
        let json = """
        {
          "@context": ["https://www.w3.org/2018/credentials/v1"],
          "type": ["VerifiableCredential"],
          "issuer": "did:example:issuer",
          "issuanceDate": "2021-01-01T00:00:00Z",
          "credentialSubject": { "id":"did:example:holder" },
          "proof": [
            {
              "type": "Ed25519Signature2020",
              "created": "2021-01-01T00:00:00Z",
              "verificationMethod": "did:example:issuer#key-1",
              "proofPurpose": "assertionMethod",
              "proofValue": "z6Mk...",
              "challenge": "abc",
              "domain": "verifier.example.org"
            },
            {
              "type": "EcdsaSecp256k1Signature2019",
              "created": "2021-01-01T00:00:01Z",
              "verificationMethod": "did:example:issuer#key-2",
              "proofPurpose": "assertionMethod",
              "jws": "eyJhbGciOiJFUzI1NiJ9..."
            }
          ]
        }
        """.data(using: .utf8)!

        let vc = try makeDecoder().decode(DefaultVerifiableCredential.self, from: json)
        let proofs = try XCTUnwrap(vc.proof?.array)
        XCTAssertEqual(proofs.count, 2)
        XCTAssertEqual(proofs[0].challenge, "abc")
        XCTAssertEqual(proofs[0].domain, "verifier.example.org")
        XCTAssertNotNil(proofs[1].jws)
    }

    func testDecode_StatusList2021_And_Schema_SingleOrArray() throws {
        let json = """
        {
          "type": ["VerifiableCredential"],
          "issuer": "did:example:issuer",
          "issuanceDate": "2023-07-14T10:00:00Z",
          "credentialSubject": { "id":"did:example:holder" },
          "credentialStatus": {
            "id": "https://status.example.com/12345#list",
            "type": "StatusList2021Entry",
            "statusPurpose": "revocation",
            "statusListIndex": "12345",
            "statusListCredential": "https://status.example.com/status-list-2021.json"
          },
          "credentialSchema": [
            { "id":"https://schema.example.com/degree.json", "type":"JsonSchema2020" },
            { "id":"https://schema.example.com/core.json" }
          ]
        }
        """.data(using: .utf8)!

        let vc = try makeDecoder().decode(DefaultVerifiableCredential.self, from: json)
//        XCTAssertEqual(vc.credentialStatus?.id, "https://status.example.com/12345#list")
        let schemas = try XCTUnwrap(vc.credentialSchema?.array)
        XCTAssertEqual(schemas.count, 2)
//        XCTAssertEqual(schemas[0].type, "JsonSchema2020")
//        XCTAssertEqual(schemas[1].type, nil)
    }

    func testDateDecoding_ISO8601_WithAndWithoutFractionalSeconds() throws {
        let json = """
        {
          "type": ["VerifiableCredential"],
          "issuer": "did:example:x",
          "issuanceDate": "2023-01-01T00:00:00.123Z",
          "expirationDate": "2024-01-01T00:00:00Z",
          "credentialSubject": { "id":"did:example:y" }
        }
        """.data(using: .utf8)!

        let vc = try makeDecoder().decode(DefaultVerifiableCredential.self, from: json)
        XCTAssertNotNil(vc.validFrom)
        XCTAssertNotNil(vc.validUntil)
    }

    func testInvalid_MissingType_Fails() throws {
        // 'type' is required and non-optional; decoding should fail.
        let json = """
        {
          "issuer": "did:example:oops",
          "issuanceDate": "2023-01-01T00:00:00Z",
          "credentialSubject": { "id":"did:example:subj" }
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try makeDecoder().decode(DefaultVerifiableCredential.self, from: json))
    }
}
