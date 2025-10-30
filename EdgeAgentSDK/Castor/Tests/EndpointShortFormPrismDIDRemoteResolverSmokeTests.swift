import Domain
@testable import Castor
import XCTest

final class EndpointShortFormPrismDIDRemoteResolverSmokeTests: XCTestCase {
    func testMethodIsPrism() {
        let sut = EndpointShortFormPrismDIDRemoteResolver(
            urlBuilder: DIDDocumentUrlBuilderMock(),
            downloader: DownloaderMock(result: .failure(MockError.forced)),
            serializer: DIDDocumentSerializerMock(result: .failure(MockError.forced))
        )
        XCTAssertEqual(sut.method, "prism")
    }

    func testTrimsLongFormBeforeBuildingURL() async {
        let longForm = DID(method: "prism", methodId: "abc:def")
        let expectedShort = DID(method: "prism", methodId: "abc")
        let urlBuilder = DIDDocumentUrlBuilderMock()
        let downloader = DownloaderMock(result: .success(Data("{}".utf8)))
        let serializer = DIDDocumentSerializerMock(result: .failure(MockError.forced))

        let sut = EndpointShortFormPrismDIDRemoteResolver(
            urlBuilder: urlBuilder,
            downloader: downloader,
            serializer: serializer
        )

        do {
            _ = try await sut.resolve(did: longForm)
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(urlBuilder.dids.first, expectedShort)
        }
    }

    func testIntegrationWithGithubResolver() async throws {
        let githubResolver = EndpointShortFormPrismDIDRemoteResolver.githubResolver()
        let document = try await githubResolver.resolve(did: DID(string: "did:prism:076b993f6070d39ee0f0964970ef3d07af3e821cb51106952100fa803b03cc51"))
    }
}
