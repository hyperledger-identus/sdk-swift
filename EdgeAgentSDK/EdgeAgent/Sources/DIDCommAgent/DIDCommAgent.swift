import Builders
import Combine
import Core
import Domain
import Foundation

public class DIDCommAgent {
    /// Enumeration representing the current state of the agent.
    public enum State: String {
        case stopped
        case starting
        case running
        case stopping
    }
    
    /// Represents the current state of the agent.
    public private(set) var state = State.stopped
    
    /// The mediator routing DID if one is currently registered.
    public var mediatorRoutingDID: DID? {
        connectionManager?.mediationHandler.mediator?.routingDID
    }
    
    public let mercury: Mercury
    public let edgeAgent: EdgeAgent
    public var apollo: Apollo & KeyRestoration { edgeAgent.apollo }
    public var castor: Castor { edgeAgent.castor }
    public var pluto: Pluto { edgeAgent.pluto }
    public var pollux: Pollux { edgeAgent.pollux }
    var logger: SDKLogger { edgeAgent.logger }

    var mediationHandler: MediatorHandler?

    var connectionManager: ConnectionsManagerImpl?
    var cancellables = [AnyCancellable]()
    // Not a "stream"
    var messagesStreamTask: Task<Void, Error>?

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
        edgeAgent: EdgeAgent,
        mercury: Mercury,
        mediationHandler: MediatorHandler? = nil
    ) {
        self.edgeAgent = edgeAgent
        self.mercury = mercury
        self.mediationHandler = mediationHandler
        mediationHandler.map {
            self.connectionManager = ConnectionsManagerImpl(
                castor: edgeAgent.castor,
                mercury: mercury,
                pluto: edgeAgent.pluto,
                mediationHandler: $0,
                pairings: []
            )
        }
    }

    /**
      Convenience initializer for `EdgeAgent` that allows for optional initialization of seed data and mediator service endpoint.

      - Parameters:
        - seedData: Optional seed data for creating a new seed. If not provided, a random seed will be generated.
        - mediatorServiceEnpoint: Optional DID representing the service endpoint of the mediator. If not provided, the default Prism mediator endpoint will be used.
    */
    public convenience init(
        seedData: Data? = nil,
        mediatorDID: DID
    ) {
        let edgeAgent = EdgeAgent(seedData: seedData)
        let secretsStream = createSecretsStream(
            keyRestoration: edgeAgent.apollo,
            pluto: edgeAgent.pluto,
            castor: edgeAgent.castor
        )

        let mercury = MercuryBuilder(
            castor: edgeAgent.castor,
            secretsStream: secretsStream
        ).build()

        self.init(
            edgeAgent: edgeAgent,
            mercury: mercury,
            mediationHandler: BasicMediatorHandler(
                mediatorDID: mediatorDID,
                mercury: mercury,
                store: BasicMediatorHandler.PlutoMediatorStoreImpl(pluto: edgeAgent.pluto)
            )
        )
    }

    public func setupMediatorHandler(mediationHandler: MediatorHandler) async throws {
        try await stop()
        self.mediationHandler = mediationHandler
        self.connectionManager = ConnectionsManagerImpl(
            castor: castor,
            mercury: mercury,
            pluto: pluto,
            mediationHandler: mediationHandler,
            pairings: []
        )
    }

    public func setupMediatorDID(did: DID) async throws {
        let mediatorHandler = BasicMediatorHandler(
            mediatorDID: did,
            mercury: mercury,
            store: BasicMediatorHandler.PlutoMediatorStoreImpl(pluto: pluto)
        )
        try await setupMediatorHandler(mediationHandler: mediatorHandler)
    }

    /**
     Start the EdgeAgent and Mediator services

     - Throws: EdgeAgentError.noMediatorAvailableError if no mediator is available,
     as well as any error thrown by `createNewPeerDID` and `connectionManager.registerMediator`
    */
    public func start() async throws {
        guard
            let connectionManager,
            state == .stopped
        else { return }
        logger.info(message: "Starting agent")
        state = .starting
        do {
            try await connectionManager.startMediator()
        } catch EdgeAgentError.noMediatorAvailableError {
            let hostDID = try await createNewPeerDID(updateMediator: false)
            try await connectionManager.registerMediator(hostDID: hostDID)
        }
        try await edgeAgent.firstLinkSecretSetup()
        state = .running
        logger.info(message: "Mediation Achieved", metadata: [
            .publicMetadata(key: "Routing DID", value: mediatorRoutingDID?.string ?? "")
        ])
        logger.info(message: "Agent running")
    }

    /**
      This function is used to stop the EdgeAgent.
      The function sets the state of EdgeAgent to .stopping.
      All ongoing events that was created by the EdgeAgent are stopped.
      After all the events are stopped the state of the EdgeAgent is set to .stopped.

      - Throws: If the current state is not running throws error.
      */
     public func stop() async throws {
         guard state == .running else { return }
         logger.info(message: "Stopping agent")
         state = .stopping
         cancellables.forEach { $0.cancel() }
         connectionManager?.stopAllEvents()
         state = .stopped
         logger.info(message: "Agent not running")
     }
}

private func createSecretsStream(
    keyRestoration: KeyRestoration,
    pluto: Pluto,
    castor: Castor
) -> AnyPublisher<[Secret], Error> {
    pluto.getAllKeys()
        .first()
        .flatMap { keys in
            Future {
                let privateKeys = await keys.asyncMap {
                    try? await keyRestoration.restorePrivateKey($0)
                }.compactMap { $0 }
                return try parsePrivateKeys(
                    privateKeys: privateKeys,
                    castor: castor
                )
            }
        }
        .eraseToAnyPublisher()
}

private func parsePrivateKeys(
    privateKeys: [PrivateKey],
    castor: Castor
) throws -> [Domain.Secret] {
    return try privateKeys
        .map { $0 as? (PrivateKey & ExportableKey & StorableKey) }
        .compactMap { $0 }
        .map { privateKey in
        return privateKey
    }
    .map { privateKey in
        try parseToSecret(
            privateKey: privateKey,
            identifier: privateKey.identifier
        )
    }
}

private func parseToSecret(privateKey: PrivateKey & ExportableKey, identifier: String) throws -> Domain.Secret {
    let jwk = privateKey.jwk
    guard
        let dataJson = try? JSONEncoder().encode(jwk),
        let stringJson = String(data: dataJson, encoding: .utf8)
    else {
        throw CommonError.invalidCoding(message: "Could not encode privateKey.jwk")
    }
    return .init(
        id: identifier,
        type: .jsonWebKey2020,
        secretMaterial: .jwk(value: stringJson)
    )
}
