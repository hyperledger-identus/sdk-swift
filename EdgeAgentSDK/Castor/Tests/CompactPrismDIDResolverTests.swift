import XCTest
import Domain
@testable import Castor

final class CompactPrismDIDResolverTests: XCTestCase {
    func testUsesShortFormResolverWhenItSucceeds() async throws {
        let did = DID(method: "prism", methodId: "abc")
        let expected = DIDDocument(id: did, coreProperties: [])

        let short = DIDResolverMock(result: .success(expected))
        let long = DIDResolverMock(result: .failure(MockError.forced))
        let sut = CompactPrismDIDResolver(longFormResolver: long, shortFormResolver: short)
        let doc = try await sut.resolve(did: did)

        XCTAssertEqual(doc.id, did)
        XCTAssertEqual(short.calls, [did])
        XCTAssertTrue(long.calls.isEmpty)
    }

    func testFallsBackToLongFormWhenShortFailsAndDIDIsLongForm() async throws {
        let longForm = DID(method: "prism", methodId: "abc:def")
        let expected = DIDDocument(id: longForm, coreProperties: [])

        let short = DIDResolverMock(result: .failure(MockError.forced))
        let long = DIDResolverMock(result: .success(expected))
        let sut = CompactPrismDIDResolver(longFormResolver: long, shortFormResolver: short)
        let doc = try await sut.resolve(did: longForm)

        XCTAssertEqual(doc.id, longForm)
        XCTAssertEqual(short.calls, [longForm])
        XCTAssertEqual(long.calls, [longForm])
    }

    func testRethrowsWhenShortFailsAndDIDIsShortForm() async {
        let shortForm = DID(method: "prism", methodId: "abc")
        let short = DIDResolverMock(result: .failure(MockError.forced))
        let long = DIDResolverMock(result: .success(DIDDocument(id: shortForm, coreProperties: [])))
        let sut = CompactPrismDIDResolver(longFormResolver: long, shortFormResolver: short)
        do {
            _ = try await sut.resolve(did: shortForm)
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(long.calls.isEmpty)
        }
    }
}
