import Builders
import Combine
import Core
import Domain
import Foundation

/// EdgeAgent class is responsible for handling the connection to other agents in the network using
/// a provided Mediator Service Endpoint and seed data.
public class EdgeAgent {
    /// Represents the seed data used to create a unique DID.
    public let seed: Seed

    let logger = SDKLogger(category: .edgeAgent)
    public let apollo: Apollo & KeyRestoration
    public let castor: Castor
    public let pluto: Pluto
    public let pollux: Pollux & CredentialImporter
    public let credentialPlugins: [PolluxPlugin]

    public static func setupLogging(logLevels: [LogComponent: LogLevel]) {
        SDKLogger.logLevels = logLevels
    }

    /// Initializes a EdgeAgent with the given dependency objects and seed data.
    ///
    /// - Parameters:
    ///   - apollo: An instance of Apollo.
    ///   - castor: An instance of Castor.
    ///   - pluto: An instance of Pluto.
    ///   - pollux: An instance of Pollux.
    ///   - mercury: An instance of Mercury.
    ///   - seed: A unique seed used to generate the unique DID.
    ///   - mediatorServiceEnpoint: The endpoint of the Mediator service to use.
    public init(
        apollo: Apollo & KeyRestoration,
        castor: Castor,
        pluto: Pluto,
        pollux: Pollux & CredentialImporter,
        credentialPlugins: [PolluxPlugin] = [],
        seed: Seed? = nil
    ) {
        self.apollo = apollo
        self.castor = castor
        self.pluto = pluto
        self.pollux = pollux
        self.credentialPlugins = credentialPlugins
        self.seed = seed ?? apollo.createRandomSeed().seed
    }

    /**
      Convenience initializer for `EdgeAgent` that allows for optional initialization of seed data and mediator service endpoint.

      - Parameters:
        - seedData: Optional seed data for creating a new seed. If not provided, a random seed will be generated.
        - mediatorServiceEnpoint: Optional DID representing the service endpoint of the mediator. If not provided, the default Prism mediator endpoint will be used.
    */
    public convenience init(seedData: Data? = nil) {
        let apollo = ApolloBuilder().build()
        let castor = CastorBuilder(apollo: apollo).build()
        let pluto = PlutoBuilder().build()
        let pollux = PolluxBuilder(pluto: pluto, castor: castor).build()

        let seed = seedData.map { Seed(value: $0) } ?? apollo.createRandomSeed().seed
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
