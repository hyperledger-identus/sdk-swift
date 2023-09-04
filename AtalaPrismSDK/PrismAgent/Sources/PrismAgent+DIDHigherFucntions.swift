import Combine
import Domain
import Foundation

// MARK: DID High Level functionalities
public extension PrismAgent {
    /// Enumeration representing the type of DID used.
    enum DIDType {
        case prism
        case peer
    }

    /**
        This function will use the provided DID to sign a given message
        - Parameters:
        - did: The DID which will be used to sign the message.
        - message: The message to be signed
        - Throws:
        - PrismAgentError.cannotFindDIDKeyPairIndex If the DID provided has no register with the Agent
        - Any other errors thrown by the `getPrismDIDInfo` function or the `createKeyPair` function
        - Returns:
        - Signature: The signature of the message.
    */
    func signWith(did: DID, message: Data) async throws -> Signature {
        let pluto = self.pluto
        let info = try await pluto
            // First get DID info (KeyPathIndex in this case)
            .getDIDInfo(did: did)
            .first()
            .await()

        guard
            let storedPrivateKey = info?.privateKeys.first
        else {
            logger.error(
                message: """
Could not find key in storage please use Castor instead and provide the private key
"""
            )
            throw PrismAgentError.cannotFindDIDKeyPairIndex
        }

        let privateKey = try await apollo.restorePrivateKey(
            identifier: storedPrivateKey.restorationIdentifier,
            data: storedPrivateKey.storableData
        )

        logger.debug(message: "Signing message", metadata: [
            .maskedMetadataByLevel(key: "messageB64", value: message.base64Encoded(), level: .debug)
        ])

        guard let signable = privateKey.signing else {
            throw KeyError.keyRequiresConformation(conformations: ["SignableKey"])
        }

        return try await signable.sign(data: message)
    }

    /// This method create a new Prism DID, that can be used to identify the agent and interact with other agents.
    /// - Parameters:
    ///   - keyPathIndex: key path index used to identify the DID
    ///   - alias: An alias that can be used to identify the DID
    ///   - services: an array of services associated to the DID
    /// - Returns: The new created DID
    func createNewPrismDID(
        keyPathIndex: Int? = nil,
        alias: String? = nil,
        services: [DIDDocument.Service] = []
    ) async throws -> DID {
        let seed = self.seed
        let apollo = self.apollo
        let castor = self.castor

        let lastKeyPairIndex = try await pluto
            .getPrismLastKeyPairIndex()
            .first()
            .await()

        // If the user provided a key path index use it, if not use the last + 1
        let index = keyPathIndex ?? (lastKeyPairIndex + 1)
        // Create the key pair
        let privateKey = try apollo.createPrivateKey(parameters: [
            KeyProperties.type.rawValue: "EC",
            KeyProperties.seed.rawValue: seed.value.base64Encoded(),
            KeyProperties.curve.rawValue: KnownKeyCurves.secp256k1.rawValue,
            KeyProperties.derivationPath.rawValue: DerivationPath(index: index).keyPathString()
        ])

        let newDID = try castor.createPrismDID(masterPublicKey: privateKey.publicKey(), services: services)
        logger.debug(message: "Created new Prism DID", metadata: [
            .maskedMetadataByLevel(key: "DID", value: newDID.string, level: .debug),
            .maskedMetadataByLevel(key: "keyPathIndex", value: "\(index)", level: .debug)
        ])

        try await registerPrismDID(did: newDID, privateKey: privateKey, alias: alias)
        return newDID
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
        logger.debug(message: "Register of DID in storage", metadata: [
            .maskedMetadataByLevel(key: "DID", value: did.string, level: .debug)
        ])

        let storablePrivateKeys = try [privateKey]
            .map {
                guard let storablePrivateKey = $0 as? (PrivateKey & StorableKey) else {
                    throw KeyError.keyRequiresConformation(conformations: ["PrivateKey", "StorableKey"])
                }
                return storablePrivateKey
            }
        try await pluto
            .storeDID(did: did, privateKeys: storablePrivateKeys, alias: alias)
            .first()
            .await()
    }

    /// This function creates a new Peer DID, stores it in pluto database and updates the mediator if requested.
    ///
    /// - Parameters:
    ///   - services: The services associated to the new DID.
    ///   - updateMediator: Indicates if the new DID should be added to the mediator's list. It will as well add the mediator service.
    /// - Returns: A new DID
    /// - Throws: PrismAgentError, if updateMediator is true and there is no mediator available or if storing the new DID failed
    func createNewPeerDID(
        services: [DIDDocument.Service] = [],
        alias: String? = "",
        updateMediator: Bool
    ) async throws -> DID {
        let keyAgreementPrivateKey = try apollo.createPrivateKey(parameters: [
            KeyProperties.type.rawValue: "EC",
            KeyProperties.curve.rawValue: KnownKeyCurves.x25519.rawValue
        ])

        let authenticationPrivateKey = try apollo.createPrivateKey(parameters: [
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
    /// - Throws: PrismAgentError, if updateMediator is true and there is no mediator available or if storing the new DID failed
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
    /// - Throws: PrismAgentError, if updateMediator is true and there is no mediator available
    func updateMediatorWithDID(did: DID) async throws {
        logger.debug(message: "Update mediator key list with DID", metadata: [
            .maskedMetadataByLevel(key: "DID", value: did.string, level: .debug)
        ])

        try await mediationHandler?.updateKeyListWithDIDs(dids: [did])
    }

    /// This function gets the DID information (alias) for a given DID
    ///
    /// - Parameter did: The DID for which the information is requested
    /// - Returns: A tuple containing the DID and the alias (if available), or nil if the DID method is not recognized
    /// - Throws: An error if there was a problem fetching the information
    func getDIDInfo(did: DID) async throws -> (did: DID, alias: String?)? {
        let pluto = self.pluto
        switch did.method {
        case "prism":
            return try await pluto
                .getPrismDIDInfo(did: did)
                .map {
                    $0.map { ($0.did, $0.alias) }
                }
                .first()
                .await()
        case "peer":
            return try await pluto
                .getPeerDIDInfo(did: did)
                .map {
                    $0.map { ($0.did, $0.alias) }
                }
                .first()
                .await()
        default:
            return nil
        }
    }

    /// This function registers a DID pair in the `pluto` store
    ///
    /// - Parameter pair: The DID pair to register
    /// - Throws: An error if there was a problem storing the pair
    func registerDIDPair(pair: DIDPair) async throws {
        try await pluto.storeDIDPair(pair: pair)
        .first()
        .await()
    }

    /// This function gets all the DID pairs from the `pluto` store
    /// 
    /// - Returns: A publisher that emits an array of `DIDPair` objects, or an error if there was a problem getting the pairs
    func getAllDIDPairs() -> AnyPublisher<[DIDPair], Error> {
        pluto.getAllDidPairs()
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
