import Domain
@testable import EdgeAgent
import XCTest

final class RequestCredentialTests: XCTestCase {
    func testWhenValidRequestMessageThenInitRequestCredential() throws {
        let fromDID = DID(index: 0)
        let toDID = DID(index: 1)
        let validRequestCredential = RequestCredential3_0(
            body: .init(
                goalCode: "test1",
                comment: "test1"
            ),
            type: ProtocolTypes.didcommRequestCredential3_0.rawValue,
            attachments: [],
            thid: "1",
            from: fromDID,
            to: toDID
        )
        let requestMessage = try validRequestCredential.makeMessage()
        let testRequestCredential = try RequestCredential3_0(fromMessage: requestMessage)
        XCTAssertEqual(validRequestCredential, testRequestCredential)
    }

    func testWhenInvalidRequestMessageThenInitRequestCredential() throws {
        let invalidRequestCredential = Message(
            piuri: "InvalidType",
            from: nil,
            to: nil,
            body: Data()
        )

        XCTAssertThrowsError(try RequestCredential(fromMessage: invalidRequestCredential))
    }

    func testWhenValidOfferMessageThenInitRequestCredential() throws {
        let fromDID = DID(index: 0)
        let toDID = DID(index: 1)
        let validOfferCredential = OfferCredential3_0(
            id: "test",
            body: .init(
                credentialPreview: .init(
                    schemaId: "test",
                    attributes: [
                        .init(name: "test1", value: "test", mediaType: "test.x")
                    ]
                )
            ),
            type: ProtocolTypes.didcommOfferCredential3_0.rawValue,
            attachments: [],
            thid: "1",
            from: fromDID,
            to: toDID
        )

        let testRequestCredential = try RequestCredential3_0.makeRequestFromOfferCredential(offer: validOfferCredential)
        XCTAssertEqual(validOfferCredential.from, testRequestCredential.to)
        XCTAssertEqual(validOfferCredential.to, testRequestCredential.from)
        XCTAssertEqual(validOfferCredential.attachments, testRequestCredential.attachments)
        XCTAssertEqual(validOfferCredential.thid, testRequestCredential.thid)
        XCTAssertEqual(validOfferCredential.body?.goalCode, testRequestCredential.body?.goalCode)
        XCTAssertEqual(validOfferCredential.body?.comment, testRequestCredential.body?.comment)
    }
}
