import Domain
@testable import EdgeAgent
import XCTest

final class IssueCredentialTests: XCTestCase {
    func testWhenValidIssueMessageThenInitIssueCredential() throws {
        let fromDID = DID(index: 0)
        let toDID = DID(index: 1)
        let validIssueCredential = IssueCredential3_0(
            body: .init(),
            type: ProtocolTypes.didcommIssueCredential3_0.rawValue,
            attachments: [],
            thid: "1",
            from: fromDID,
            to: toDID
        )
        let issueMessage = try validIssueCredential.makeMessage()

        let testIssueCredential = try IssueCredential3_0(fromMessage: issueMessage)
        XCTAssertEqual(validIssueCredential, testIssueCredential)
    }

    func testWhenInvalidIssueMessageThenInitIssueCredential() throws {
        let invalidIssueCredential = Message(
            piuri: "InvalidType",
            from: nil,
            to: nil,
            body: Data()
        )

        XCTAssertThrowsError(try IssueCredential(fromMessage: invalidIssueCredential))
    }

    func testWhenValidRequestMessageThenInitIssueCredential() throws {
        let fromDID = DID(index: 0)
        let toDID = DID(index: 1)
        let validRequestCredential = RequestCredential3_0(
            body: .init(),
            type: ProtocolTypes.didcommRequestCredential3_0.rawValue,
            attachments: [],
            thid: "1",
            from: fromDID,
            to: toDID
        )
        let requestMessage = try validRequestCredential.makeMessage()

        let testIssueCredential = try IssueCredential3_0.makeIssueFromRequestCredential(msg: requestMessage)
        XCTAssertEqual(validRequestCredential.from, testIssueCredential.to)
        XCTAssertEqual(validRequestCredential.to, testIssueCredential.from)
        XCTAssertEqual(validRequestCredential.attachments, testIssueCredential.attachments)
        XCTAssertEqual(validRequestCredential.id, testIssueCredential.thid)
        XCTAssertEqual(validRequestCredential.body?.goalCode, validRequestCredential.body?.goalCode)
        XCTAssertEqual(validRequestCredential.body?.comment, validRequestCredential.body?.comment)
    }
}
