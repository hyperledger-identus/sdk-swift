import Domain
import Apollo
import Castor
import Builders
import CryptoKit
import Core
import Pluto
import Pollux
@testable import EdgeAgent
import XCTest

final class CheckTests: XCTestCase {
    func testCheck() async throws {
        let apollo = ApolloBuilder().build()

        let seed = apollo.createRandomSeed()

        let privateKey = try apollo.createPrivateKey(parameters: [
            KeyProperties.type.rawValue: "EC",
            KeyProperties.seed.rawValue: seed.seed.value.base64Encoded(),
            KeyProperties.curve.rawValue: KnownKeyCurves.secp256k1.rawValue,
            KeyProperties.derivationPath.rawValue: DerivationPath().keyPathString()
        ])

        let payload = try "test".tryToData()
        let signature = try await privateKey.signing!.sign(data: payload)

        print(privateKey.raw.base64EncodedString())
        print(signature.raw.toHexString())
    }

    func testOOB() async throws {
        let oob = "https://mediator.rootsid.cloud?_oob=eyJ0eXBlIjoiaHR0cHM6Ly9kaWRjb21tLm9yZy9vdXQtb2YtYmFuZC8yLjAvaW52aXRhdGlvbiIsImlkIjoiNzk0Mjc4MzctY2MwNi00ODUzLWJiMzktNjg2ZWFjM2U2YjlhIiwiZnJvbSI6ImRpZDpwZWVyOjIuRXo2TFNtczU1NVloRnRobjFXVjhjaURCcFptODZoSzl0cDgzV29qSlVteFBHazFoWi5WejZNa21kQmpNeUI0VFM1VWJiUXc1NHN6bTh5dk1NZjFmdEdWMnNRVllBeGFlV2hFLlNleUpwWkNJNkltNWxkeTFwWkNJc0luUWlPaUprYlNJc0luTWlPaUpvZEhSd2N6b3ZMMjFsWkdsaGRHOXlMbkp2YjNSemFXUXVZMnh2ZFdRaUxDSmhJanBiSW1ScFpHTnZiVzB2ZGpJaVhYMCIsImJvZHkiOnsiZ29hbF9jb2RlIjoicmVxdWVzdC1tZWRpYXRlIiwiZ29hbCI6IlJlcXVlc3RNZWRpYXRlIiwibGFiZWwiOiJNZWRpYXRvciIsImFjY2VwdCI6WyJkaWRjb21tL3YyIl19fQ"
        let agent = DIDCommAgent(mediatorDID: DID(method: "peer", methodId: "123"))

        let parsed = try await agent.parseInvitation(str: oob)
        print(parsed)
    }
}
