import Apollo
import Domain
@testable import Castor
import XCTest

final class PeerDIDCreationTests: XCTestCase {
    func testPeerDIDCreation() throws {
        let validPeerDID = "did:peer:2.Ez6LSoHkfN1Y4nK9RCjx7vopWsLrMGNFNgTNZgoCNQrTzmb1n.Vz6MknRZmapV7uYZQuZez9n9N3tQotjRN18UGS68Vcfo6gR4h.SeyJzIjp7ImEiOltdLCJyIjpbImRpZDpleGFtcGxlOnNvbWVtZWRpYXRvciNzb21la2V5Il0sInVyaSI6Imh0dHBzOi8vZXhhbXBsZS5jb20vZW5kcG9pbnQifSwidCI6ImRtIn0"
        let apollo = ApolloImpl()
        let castor = CastorImpl(apollo: apollo)
        let keyAgreementPrivateKey = try apollo.createPrivateKey(parameters: [
            KeyProperties.type.rawValue: "EC",
            KeyProperties.curve.rawValue: KnownKeyCurves.x25519.rawValue,
            KeyProperties.rawKey.rawValue: Data(base64URLEncoded: "COd9Xhr-amD7fuswWId2706JBUY_tmjp9eiNEieJeEE")!.base64Encoded()
        ])

        print(keyAgreementPrivateKey.raw.base64URLEncoded())


        let authenticationPrivateKey = try apollo.createPrivateKey(parameters: [
            KeyProperties.type.rawValue: "EC",
            KeyProperties.curve.rawValue: KnownKeyCurves.ed25519.rawValue,
            KeyProperties.rawKey.rawValue: Data(base64URLEncoded: "JLIJQ5jlkyqtGmtOth6yggJLLC0zuRhUPiBhd1-rGPs")!.base64Encoded()
        ])

        let service = DIDDocument.Service(
            id: "didcomm",
            type: .one("DIDCommMessaging"),
            serviceEndpoint: .one(.init(
                uri: "https://example.com/endpoint",
                routingKeys: ["did:example:somemediator#somekey"]
            ))
        )
        let did = try castor.createPeerDID(
            keyAgreementPublicKey: keyAgreementPrivateKey.publicKey(),
            authenticationPublicKey: authenticationPrivateKey.publicKey(),
            services: [service]
        )

        XCTAssertTrue(did.string.contains("did:peer:2.Ez6LSoHkfN1Y4nK9RCjx7vopWsLrMGNFNgTNZgoCNQrTzmb1n.Vz6MknRZmapV7uYZQuZez9n9N3tQotjRN18UGS68Vcfo6gR4h.SeyJ"))
    }

    func testResolvePeerDID() async throws {
        let peerDID = DID(
            schema: "did",
            method: "peer",
            methodId: "2.Ez6LSci5EK4Ezue5QA72ZX71QUbXY2xr5ygRw7wM1WJigTNnd.Vz6MkqgCXHEGr2wJZANPZGC8WFmeVuS3abAD9uvh7mTXygCFv.SeyJ0IjoiZG0iLCJzIjoibG9jYWxob3N0OjgwODIiLCJyIjpbXSwiYSI6WyJkaWRjb21tL3YyIl19"
        )

        let apollo = ApolloImpl()
        let castor = CastorImpl(apollo: apollo)
        let document = try await castor.resolveDID(did: peerDID)
    }
}
