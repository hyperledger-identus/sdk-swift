import Combine
import Domain
import Foundation

// MARK: DID High Level functionalities
public extension DIDCommAgent {

    /// This method create a new Prism DID, that can be used to identify the agent and interact with other agents.
    /// - Parameters:
    ///   - keyPathIndex: key path index used to identify the DID
    ///   - alias: An alias that can be used to identify the DID
    ///   - services: an array of services associated to the DID
    /// - Returns: The new created DID
    func createNewPrismDID(
        keys: [(KeyPurpose, PrivateKey)] = [],
        keyPathIndex: Int? = nil,
        alias: String? = nil,
        services: [DIDDocument.Service] = []
    ) async throws -> DID {
        try await edgeAgent.createNewPrismDID(
            keys: keys,
            keyPathIndex: keyPathIndex,
            alias: alias,
            services: services
        )
    }

    /// This method registers a Prism DID, that can be used to identify the agent and interact with other agents.
    /// - Parameters:
    ///   - did: the DID which will be registered.
    ///   - keyPathIndex: key path index used to identify the DID
    ///   - alias: An alias that can be used to identify the DID
    /// - Returns: The new created DID
    func registerPrismDID(
        did: DID,
        privateKey: PrivateKey,
        alias: String? = nil
    ) async throws {
        try await edgeAgent.registerPrismDID(
            did: did,
            privateKey: privateKey,
            alias: alias
        )
    }
    /// This function creates a new Peer DID, stores it in pluto database and updates the mediator if requested.
    ///
    /// - Parameters:
    ///   - services: The services associated to the new DID.
    ///   - updateMediator: Indicates if the new DID should be added to the mediator's list. It will as well add the mediator service.
    /// - Returns: A new DID
    /// - Throws: EdgeAgentError, if updateMediator is true and there is no mediator available or if storing the new DID failed
    func createNewPeerDID(
        services: [DIDDocument.Service] = [],
        alias: String? = "",
        updateMediator: Bool
    ) async throws -> DID {
        var keyAgreementPrivateKey = try apollo.createPrivateKey(parameters: [
            KeyProperties.type.rawValue: "EC",
            KeyProperties.curve.rawValue: KnownKeyCurves.x25519.rawValue
        ])

        var authenticationPrivateKey = try apollo.createPrivateKey(parameters: [
            KeyProperties.type.rawValue: "EC",
            KeyProperties.curve.rawValue: KnownKeyCurves.ed25519.rawValue
        ])

        let withServices: [DIDDocument.Service]
        if updateMediator, let routingDID = mediatorRoutingDID?.string {
            withServices = services + [.init(
                id: "#didcomm-1",
                type: ["DIDCommMessaging"],
                serviceEndpoint: [.init(
                    uri: routingDID
                )])]
        } else {
            withServices = services
        }

        let newDID = try castor.createPeerDID(
            keyAgreementPublicKey: keyAgreementPrivateKey.publicKey(),
            authenticationPublicKey: authenticationPrivateKey.publicKey(),
            services: withServices
        )

        let didDocument = try await castor.resolveDID(did: newDID)
        didDocument.authenticate.first.map { authenticationPrivateKey.identifier = $0.id.string }
        didDocument.keyAgreement.first.map { keyAgreementPrivateKey.identifier = $0.id.string }

        logger.debug(message: "Created new Peer DID", metadata: [
            .maskedMetadataByLevel(key: "DID", value: newDID.string, level: .debug)
        ])

        try await registerPeerDID(
            did: newDID,
            privateKeys: [
                keyAgreementPrivateKey,
                authenticationPrivateKey
            ],
            alias: alias,
            updateMediator: updateMediator
        )

        return newDID
    }

    /// This function registers a Peer DID, stores it and his private key in pluto database and updates the mediator if requested.
    ///
    /// - Parameters:
    ///   - services: The services associated to the new DID.
    ///   - updateMediator: Indicates if the new DID should be added to the mediator's list.
    /// - Returns: A new DID
    /// - Throws: EdgeAgentError, if updateMediator is true and there is no mediator available or if storing the new DID failed
    func registerPeerDID(
        did: DID,
        privateKeys: [PrivateKey],
        alias: String?,
        updateMediator: Bool
    ) async throws {
        if updateMediator {
            try await updateMediatorWithDID(did: did)
        }
        logger.debug(message: "Register of DID in storage", metadata: [
            .maskedMetadataByLevel(key: "DID", value: did.string, level: .debug)
        ])

        let storablePrivateKeys = try privateKeys
            .map {
                guard let storablePrivateKey = $0 as? (PrivateKey & StorableKey) else {
                    throw KeyError.keyRequiresConformation(conformations: ["PrivateKey", "StorableKey"])
                }
                return storablePrivateKey
            }

        try await pluto
            .storePeerDID(
                did: did,
                privateKeys: storablePrivateKeys,
                alias: alias
            )
            .first()
            .await()
    }

    /// This function updates the mediator key list with a new DID.
    ///
    /// - Parameters:
    ///   - services: The services associated to the new DID.
    ///   - updateMediator: Indicates if the new DID should be added to the mediator's list.
    /// - Returns: A new DID
    /// - Throws: EdgeAgentError, if updateMediator is true and there is no mediator available
    func updateMediatorWithDID(did: DID) async throws {
        logger.debug(message: "Update mediator key list with DID", metadata: [
            .maskedMetadataByLevel(key: "DID", value: did.string, level: .debug)
        ])

        try await mediationHandler?.updateKeyListWithDIDs(dids: [did])
    }

    /// This function gets all the DID peers from the `pluto` store
    ///
    /// - Returns: A publisher that emits an array of tuples (`DID`, `String?`) objects, or an error if there was a problem getting the dids
    func getAllRegisteredPeerDIDs() -> AnyPublisher<[(did: DID, alias: String?)], Error> {
        pluto.getAllPeerDIDs()
            .map { $0.map { ($0.did, $0.alias) } }
            .eraseToAnyPublisher()
    }
}
