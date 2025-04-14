import Combine
import Domain
import Foundation

// MARK: DID High Level functionalities
public extension EdgeAgent {
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
        - EdgeAgentError.cannotFindDIDKeyPairIndex If the DID provided has no register with the Agent
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
            throw EdgeAgentError.cannotFindDIDKeyPairIndex
        }

        let privateKey = try await apollo.restorePrivateKey(storedPrivateKey)

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
        masterPrivateKey: PrivateKey? = nil,
        keyPathIndex: Int? = nil,
        alias: String? = nil,
        services: [DIDDocument.Service] = []
    ) async throws -> DID {
        return try await createNewPrismDID(
            keys: masterPrivateKey.map { [(KeyPurpose.master, $0)] } ?? [],
            keyPathIndex: keyPathIndex,
            alias: alias,
            services: services
        )
    }

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
        let seed = self.seed
        let apollo = self.apollo
        let castor = self.castor
        var usingKeys = keys

        if keys.first(where: { $0.0 == .master })?.1 == nil {
            let lastKeyPairIndex = try await pluto
                .getPrismLastKeyPairIndex()
                .first()
                .await()

            // If the user provided a key path index use it, if not use the last + 1
            let index = keyPathIndex ?? (lastKeyPairIndex + 1)
            // Create the key pair
            let usingPrivateKey = try apollo.createPrivateKey(parameters: [
                KeyProperties.type.rawValue: "EC",
                KeyProperties.seed.rawValue: seed.value.base64Encoded(),
                KeyProperties.curve.rawValue: KnownKeyCurves.secp256k1.rawValue,
                KeyProperties.derivationPath.rawValue: EdgeAgentDerivationPath(
                    keyPurpose: .master,
                    keyIndex: index
                ).derivationPath.keyPathString()
            ])
            usingKeys.append((.master, usingPrivateKey))
        }

        if usingKeys.count == 1 {
            let lastKeyPairIndex = try await pluto
                .getPrismLastKeyPairIndex()
                .first()
                .await()

            // If the user provided a key path index use it, if not use the last + 1
            let index = keyPathIndex ?? (lastKeyPairIndex + 1)
            // Create the key pair
            let usingPrivateKey = try apollo.createPrivateKey(parameters: [
                KeyProperties.type.rawValue: "EC",
                KeyProperties.seed.rawValue: seed.value.base64Encoded(),
                KeyProperties.curve.rawValue: KnownKeyCurves.secp256k1.rawValue,
                KeyProperties.derivationPath.rawValue: EdgeAgentDerivationPath(
                    keyPurpose: .authentication,
                    keyIndex: index
                ).derivationPath.keyPathString()
            ])
            usingKeys.append((.authentication, usingPrivateKey))
        }

        let groupedKeys = Dictionary(grouping: usingKeys, by: { $0.0 })
        let finalKeys = groupedKeys.flatMap { (key, value) in
            value.enumerated().map {
                var privateKey = $0.element.1
                var publicKey = $0.element.1.publicKey()
                let identifier = "#\(key.rawValue)\($0.offset)"
                privateKey.identifier = identifier
                publicKey.identifier = identifier
                return (key, privateKey, publicKey)
            }
        }

        let newDID = try castor.createDID(
            method: "prism",
            keys: finalKeys.map {
                ($0, $2)
            },
            services: services)

        let finalKeysAfterDid = groupedKeys.flatMap { (key, value) in
            value.enumerated().map {
                var privateKey = $0.element.1
                var publicKey = $0.element.1.publicKey()
                let identifier = DIDUrl(did: newDID, fragment: "\(key.rawValue)\($0.offset)").string
                privateKey.identifier = identifier
                publicKey.identifier = identifier
                return (key, privateKey, publicKey)
            }
        }

        logger.debug(message: "Created new Prism DID", metadata: [
            .maskedMetadataByLevel(key: "DID", value: newDID.string, level: .debug),
            .maskedMetadataByLevel(key: "keyPathIndex", value: "\(index)", level: .debug)
        ])

        try await registerPrismDID(
            did: newDID,
            keys: finalKeysAfterDid.map(\.1),
            alias: alias)
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

    /// This method registers a Prism DID, that can be used to identify the agent and interact with other agents.
    /// - Parameters:
    ///   - did: the DID which will be registered.
    ///   - keyPathIndex: key path index used to identify the DID
    ///   - alias: An alias that can be used to identify the DID
    /// - Returns: The new created DID
    func registerPrismDID(
        did: DID,
        keys: [PrivateKey],
        alias: String? = nil
    ) async throws {
        logger.debug(message: "Register of DID in storage", metadata: [
            .maskedMetadataByLevel(key: "DID", value: did.string, level: .debug)
        ])

        let storablePrivateKeys = try keys
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
