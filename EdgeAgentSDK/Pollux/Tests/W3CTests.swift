import Foundation
import XCTest
@testable import Pollux
@testable import Domain
@testable import Core

final class W3CTests: XCTestCase {
    // MARK: - Helpers
    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.withoutEscapingSlashes]
        return encoder
    }

    private func sampleVCRawJSON() -> Data {
        let json = """
        {
          "@context": [
            "https://www.w3.org/ns/credentials/v2"
          ],
          "id": "urn:uuid:12345678-1234-5678-9abc-def012345678",
          "type": ["VerifiableCredential", "ExampleCredential"],
          "name": "Example VC",
          "description": "An example verifiable credential",
          "issuer": "did:example:issuer",
          "validFrom": "2024-01-01T00:00:00Z",
          "validUntil": "2025-01-01T00:00:00Z",
          "credentialSubject": {
            "id": "did:example:subject",
            "givenName": "Alice"
          },
          "credentialStatus": {
            "id": "https://example.com/status/123",
            "type": "StatusList2021"
          },
          "credentialSchema": [
            {"id": "https://example.com/schema", "type": "JsonSchema"}
          ],
          "termsOfUse": [
            {"type": "ExampleTerms"}
          ],
          "evidence": [
            {"type": "ExampleEvidence"}
          ],
          "refreshService": [
            {"type": "ExampleRefreshService"}
          ]
        }
        """
        return Data(json.utf8)
    }

    private func sampleVPJSON(single: Bool) -> Data {
        // Embed the VC payload inside a VP. When many==true, wrap as an array.
        let vc = String(data: sampleVCRawJSON(), encoding: .utf8)!
        let vcSingle = vc
        let vcMany = "[\n" + vc + ",\n" + vc + "\n]"

        let verifiableCredentialField = single ? vcSingle : vcMany
        let json = """
        {
          "@context": ["https://www.w3.org/2018/presentations/v1"],
          "type": ["VerifiablePresentation"],
          "verifiableCredential": \(verifiableCredentialField)
        \n}
        """
        return Data(json.utf8)
    }

    // MARK: - Tests: DefaultVerifiableCredential
    func testDefaultVerifiableCredential_DecodeAndReencode_RoundTrips() throws {
        let decoder = makeDecoder()
        let encoder = makeEncoder()

        // Decode sample JSON into DefaultVerifiableCredential
        let decoded = try decoder.decode(DefaultVerifiableCredential.self, from: sampleVCRawJSON())

        // Validate a few key properties
        // @context should include at least the two entries we provided
        XCTAssertTrue(decoded.context.array.contains("https://www.w3.org/ns/credentials/v2"))
        XCTAssertTrue(decoded.type.contains("VerifiableCredential"))
        XCTAssertTrue(decoded.type.contains("ExampleCredential"))
        XCTAssertEqual(decoded.id, "urn:uuid:12345678-1234-5678-9abc-def012345678")
        // validFrom should decode (required via validFrom or issuanceDate)
        XCTAssertNotNil(decoded.validFrom)

        // Build a fresh instance without raw to exercise the synthesized encoder
        let rebuilt = DefaultVerifiableCredential(
            context: decoded.context,
            id: decoded.id,
            type: decoded.type,
            name: decoded.name,
            description: decoded.description,
            issuer: decoded.issuer,
            validFrom: decoded.validFrom,
            validUntil: decoded.validUntil,
            credentialSubject: decoded.credentialSubject,
            credentialStatus: decoded.credentialStatus,
            credentialSchema: decoded.credentialSchema,
            termsOfUse: decoded.termsOfUse,
            evidence: decoded.evidence,
            refreshService: decoded.refreshService,
            proof: decoded.proof,
            raw: nil
        )

        let encoded = try encoder.encode(rebuilt)
        // Decode again and compare salient fields
        let roundTripped = try decoder.decode(DefaultVerifiableCredential.self, from: encoded)

        XCTAssertEqual(roundTripped.id, decoded.id)
        XCTAssertEqual(roundTripped.type, decoded.type)
        XCTAssertEqual(roundTripped.context.array, decoded.context.array)
        XCTAssertEqual(roundTripped.validFrom, decoded.validFrom)
        XCTAssertEqual(roundTripped.validUntil, decoded.validUntil)
    }

    // MARK: - Tests: Generic VerifiableCredential (same generics as default alias)
    func testGenericVerifiableCredential_DecodeAndReencode_RoundTrips() throws {
        typealias GenericVC = VerifiableCredential<
            DefaultIdentifiableObject,
            OneOrMany<DefaultObject>,
            DefaultObject,
            DefaultIdentifiableAndTypeObject,
            DefaultObject,
            DefaultObject,
            DefaultObject,
            DefaultLinkedDataProof
        >

        let decoder = makeDecoder()
        let encoder = makeEncoder()

        let decoded = try decoder.decode(GenericVC.self, from: sampleVCRawJSON())

        // Sanity checks
        XCTAssertTrue(decoded.type.contains("VerifiableCredential"))
        XCTAssertNotNil(decoded.validFrom)

        // Rebuild without raw and round-trip
        let rebuilt = GenericVC(
            context: decoded.context,
            id: decoded.id,
            type: decoded.type,
            name: decoded.name,
            description: decoded.description,
            issuer: decoded.issuer,
            validFrom: decoded.validFrom,
            validUntil: decoded.validUntil,
            credentialSubject: decoded.credentialSubject,
            credentialStatus: decoded.credentialStatus,
            credentialSchema: decoded.credentialSchema,
            termsOfUse: decoded.termsOfUse,
            evidence: decoded.evidence,
            refreshService: decoded.refreshService,
            proof: decoded.proof,
            raw: nil
        )

        let encoded = try encoder.encode(rebuilt)
        let roundTripped = try decoder.decode(GenericVC.self, from: encoded)

        XCTAssertEqual(roundTripped.id, decoded.id)
        XCTAssertEqual(roundTripped.type, decoded.type)
        XCTAssertEqual(roundTripped.context.array, decoded.context.array)
    }

    // MARK: - Tests: VerifiablePresentation (single VC)
    func testVerifiablePresentationSingle_DecodeAndReencode_RoundTrips() throws {
        typealias VPSingle = VerifiablePresentation<DefaultVerifiableCredential>

        let decoder = makeDecoder()
        let encoder = makeEncoder()

        let data = sampleVPJSON(single: true)
        let decoded = try decoder.decode(VPSingle.self, from: data)

        XCTAssertTrue(decoded.type.array.contains("VerifiablePresentation"))
        // The embedded credential should decode and carry VC types
        let embedded = decoded.verifiableCredential
        XCTAssertTrue(embedded.type.contains("VerifiableCredential"))

        // Rebuild without raw to exercise synthesized encoding
        let rebuilt = VPSingle(
            context: decoded.context,
            type: decoded.type,
            verifiableCredential: embedded,
            raw: nil
        )

        let encoded = try encoder.encode(rebuilt)
        let roundTripped = try decoder.decode(VPSingle.self, from: encoded)

        XCTAssertEqual(roundTripped.type.array, decoded.type.array)
        XCTAssertEqual(roundTripped.context.array, decoded.context.array)
        XCTAssertEqual(roundTripped.verifiableCredential.type, embedded.type)
    }

    // MARK: - Tests: VerifiablePresentation (many VCs via OneOrMany)
    func testVerifiablePresentationMany_DecodeAndReencode_RoundTrips() throws {
        typealias VPMany = VerifiablePresentation<OneOrMany<DefaultVerifiableCredential>>

        let decoder = makeDecoder()
        let encoder = makeEncoder()

        let data = sampleVPJSON(single: false)
        let decoded = try decoder.decode(VPMany.self, from: data)

        XCTAssertTrue(decoded.type.array.contains("VerifiablePresentation"))
        // Expect at least two credentials in the array
        let embeddedMany = decoded.verifiableCredential.array
        XCTAssertEqual(embeddedMany.count, 2)
        XCTAssertTrue(embeddedMany.first?.type.contains("VerifiableCredential") ?? false)

        // Rebuild without raw and round-trip
        let rebuilt = VPMany(
            context: decoded.context,
            type: decoded.type,
            verifiableCredential: decoded.verifiableCredential,
            raw: nil
        )

        let encoded = try encoder.encode(rebuilt)
        let roundTripped = try decoder.decode(VPMany.self, from: encoded)

        XCTAssertEqual(roundTripped.type.array, decoded.type.array)
        XCTAssertEqual(roundTripped.context.array, decoded.context.array)
        XCTAssertEqual(roundTripped.verifiableCredential.array.count, embeddedMany.count)
    }
}
