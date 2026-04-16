import Builders
import Combine
import Core
import Domain
import Foundation

/// EdgeAgent class is responsible for handling the connection to other agents in the network using
/// a provided Mediator Service Endpoint and seed data.
public class EdgeAgent {
    /// Represents the seed data used to create a unique DID.
    public let seed: () async throws -> Seed

    let logger = SDKLogger(category: LogComponent.edgeAgent)
    public let apollo: Apollo & KeyRestoration
    public let castor: Castor
    public let pluto: Pluto
    public let pollux: Pollux & CredentialImporter

    public static func setupLogging(logLevels: [LogComponent: LogLevel]) {
        let mapped: [String: LogLevel] = Dictionary(uniqueKeysWithValues: logLevels.map { ($0.key.rawValue, $0.value) })
        SDKLogger.logLevels = mapped
    }

    /// Initializes a EdgeAgent with the given dependency objects and seed data.
    ///
    /// - Parameters:
    ///   - apollo: An instance of Apollo.
    ///   - castor: An instance of Castor.
    ///   - pluto: An instance of Pluto.
    ///   - pollux: An instance of Pollux.
    ///   - mercury: An instance of Mercury.
    ///   - seed: A seed builder that will be called when the SDK requires to use the seed. If nil the SDK will create a random seed and use that.
    public init(
        apollo: Apollo & KeyRestoration,
        castor: Castor,
        pluto: Pluto,
        pollux: Pollux & CredentialImporter,
        seed: (() async throws -> Seed)? = nil
    ) {
        self.apollo = apollo
        self.castor = castor
        self.pluto = pluto
        self.pollux = pollux
        if let seed {
            self.seed = seed
        } else {
            let usingSeed = apollo.createRandomSeed().seed
            self.seed = { usingSeed }
        }
    }

    /**
      Convenience initializer for `EdgeAgent` that allows for optional initialization of seed data and mediator service endpoint.

      - Parameters:
        - seedDataBuilder: Optional seed builder that will be called when the SDK requires to use the seed. If nil the SDK will create a random seed and use that.
    */
    public convenience init(seedData: (() async throws -> Data)? = nil) {
        let apollo = ApolloBuilder().build()
        let castor = CastorBuilder(apollo: apollo).build()
        let pluto = PlutoBuilder().build()
        let pollux = PolluxBuilder(pluto: pluto, castor: castor).build()

        let seed: () async throws -> Seed
        if let seedData {
            seed = { try await Seed(value: seedData()) }
        } else {
            let seedData = apollo.createRandomSeed().seed
            seed = { seedData }
        }

        self.init(
            apollo: apollo,
            castor: castor,
            pluto: pluto,
            pollux: pollux,
            seed: seed
        )
    }

    func firstLinkSecretSetup() async throws {
        if try await pluto.getLinkSecret().first().await() == nil {
            let secret = try apollo.createNewLinkSecret()
            guard let storableSecret = secret.storable else {
                throw UnknownError
                    .somethingWentWrongError(customMessage: "Secret does not conform with StorableKey")
            }
            try await pluto.storeLinkSecret(secret: storableSecret).first().await()
        }
    }
}

extension DID {
    func getMethodIdKeyAgreement() -> String {
        var str = methodId.components(separatedBy: ".")[1]
        str.removeFirst()
        return str
    }
}
