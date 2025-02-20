import Domain
import Foundation

extension CastorImpl: Castor {
    /// parseDID parses a string representation of a Decentralized Identifier (DID) into a DID object. This function may throw an error if the string is not a valid DID.
    ///
    /// - Parameter str: The string representation of the DID
    /// - Returns: The DID object
    /// - Throws: An error if the string is not a valid DID
    public func parseDID(str: String) throws -> DID {
        try DID(string: str)
    }

//    /// createPrismDID creates a DID for a prism (a device or server that acts as a DID owner and controller) using a given master public key and list of services. This function may throw an error if the master public key or services are invalid.
//    ///
//    /// - Parameters:
//    ///   - masterPublicKey: The master public key of the prism
//    ///   - services: The list of services offered by the prism
//    /// - Returns: The DID of the prism
//    /// - Throws: An error if the master public key or services are invalid
//    public func createPrismDID(
//        masterPublicKey: PublicKey,
//        services: [DIDDocument.Service]
//    ) throws -> DID {
//        try CreatePrismDIDOperation(
//            apollo: apollo,
//            masterPublicKey: masterPublicKey,
//            services: services
//        ).compute()
//    }

    public func createDID(
        method: DIDMethod,
        keys: [(KeyPurpose, any PublicKey)],
        services: [DIDDocument.Service]
    ) throws -> DID {
        switch method {
        case "prism":
            return try CreatePrismDIDOperation(
                apollo: apollo,
                keys: keys,
                services: services
            ).compute()
        case "peer":
            return try CreatePeerDIDOperation(
                keys: keys,
                services: services
            ).compute()
        default:
            throw CastorError.noResolversAvailableForDIDMethod(method: method)
        }
    }

    /// createPrismDID creates a DID for a prism (a device or server that acts as a DID owner and controller) using a given master public key and list of services. This function may throw an error if the master public key or services are invalid.
    ///
    /// - Parameters:
    ///   - masterPublicKey: The master public key of the prism
    ///   - services: The list of services offered by the prism
    /// - Returns: The DID of the prism
    /// - Throws: An error if the master public key or services are invalid
    public func createPrismDID(
        masterPublicKey: PublicKey,
        services: [DIDDocument.Service]
    ) throws -> DID {
        try CreatePrismDIDOperation(
            apollo: apollo,
            keys: [(KeyPurpose.master, masterPublicKey)],
            services: services
        ).compute()
    }

    /// createPeerDID creates a DID for a peer (a device or server that acts as a DID subject) using given key agreement and authentication key pairs and a list of services. This function may throw an error if the key pairs or services are invalid.
    ///
    /// - Parameters:
    ///   - keyAgreementKeyPair: The key pair used for key agreement (establishing secure communication between peers)
    ///   - authenticationKeyPair: The key pair used for authentication (verifying the identity of a peer)
    ///   - services: The list of services offered by the peer
    /// - Returns: The DID of the peer
    /// - Throws: An error if the key pairs or services are invalid
    public func createPeerDID(
        keyAgreementPublicKey: PublicKey,
        authenticationPublicKey: PublicKey,
        services: [DIDDocument.Service]
    ) throws -> DID {
        try CreatePeerDIDOperation(
            keys: [
                (KeyPurpose.authentication, authenticationPublicKey),
                (KeyPurpose.agreement, keyAgreementPublicKey)
            ],
            services: services
        ).compute()
    }

    /// verifySignature asynchronously verifies the authenticity of a signature using the corresponding DID, challenge, and signature data. This function returns a boolean value indicating whether the signature is valid or not. This function may throw an error if the DID or signature data are invalid.
    ///
    /// - Parameters:
    ///   - did: The DID associated with the signature
    ///   - challenge: The challenge used to generate the signature
    ///   - signature: The signature data to verify
    /// - Returns: A boolean value indicating whether the signature is valid or not
    /// - Throws: An error if the DID or signature data are invalid
    public func verifySignature(
        did: DID,
        challenge: Data,
        signature: Data
    ) async throws -> Bool {
        let document = try await resolveDID(did: did)
        return try await verifySignature(
            document: document,
            challenge: challenge,
            signature: signature
        )
    }

    /// verifySignature verifies the authenticity of a signature using the corresponding DID Document, challenge, and signature data. This function returns a boolean value indicating whether the signature is valid or not. This function may throw an error if the DID Document or signature data are invalid.
    ///
    /// - Parameters:
    ///   - document: The DID Document associated with the signature
    ///   - challenge: The challenge used to generate the signature
    ///   - signature: The signature data to verify
    /// - Returns: A boolean value indicating whether the signature is valid or not
    /// - Throws: An error if the DID Document or signature data are invalid
    public func verifySignature(
        document: DIDDocument,
        challenge: Data,
        signature: Data
    ) async throws -> Bool {
        return try await VerifyDIDSignatureOperation(
            apollo: apollo,
            document: document,
            challenge: challenge,
            signature: signature
        ).compute()
    }

    /// resolveDID asynchronously resolves a DID to its corresponding DID Document. This function may throw an error if the DID is invalid or the document cannot be retrieved.
    ///
    /// - Parameter did: The DID to resolve
    /// - Returns: The DID Document associated with the DID
    /// - Throws: An error if the DID is invalid or the document cannot be retrieved
    public func resolveDID(did: DID) async throws -> DIDDocument {
        logger.debug(message: "Trying to resolve DID", metadata: [
            .maskedMetadataByLevel(key: "DID", value: did.string, level: .debug)
        ])

        guard
            let resolver = resolvers.first(where: { $0.method == did.method })
        else {
            logger.error(message: "No resolvers for DID method \(did.method)", metadata: [
                .maskedMetadataByLevel(key: "DID", value: did.string, level: .debug)
            ])
            throw CastorError.noResolversAvailableForDIDMethod(method: did.method)
        }
        return try await resolver.resolve(did: did)
    }

    public func getDIDPublicKeys(did: DID) async throws -> [PublicKey] {
        let document = try await resolveDID(did: did)

        return try await document.verificationMethods
            .asyncMap { verificationMethod -> PublicKey in
                try await verificationMethodToPublicKey(method: verificationMethod)
            }
    }

    private func verificationMethodToPublicKey(method: DIDDocument.VerificationMethod) async throws -> PublicKey {
        switch method.type {
        case "EcdsaSecp256k1VerificationKey2019", "secp256k1":
            guard let multibaseData = method.publicKeyMultibase else {
                throw CastorError.cannotRetrievePublicKeyFromDocument
            }
            return try apollo.createPublicKey(
                parameters: [
                    KeyProperties.type.rawValue: "EC",
                    KeyProperties.rawKey.rawValue: multibaseData,
                    KeyProperties.curve.rawValue: KnownKeyCurves.secp256k1.rawValue
                ])
        case "Ed25519VerificationKey2018", "ed25519":
            guard let multibaseData = method.publicKeyMultibase else {
                throw CastorError.cannotRetrievePublicKeyFromDocument
            }
            return try apollo.createPublicKey(
                parameters: [
                    KeyProperties.type.rawValue: "EC",
                    KeyProperties.rawKey.rawValue: multibaseData,
                    KeyProperties.curve.rawValue: KnownKeyCurves.ed25519.rawValue
                ])
        case "X25519KeyAgreementKey2019", "x25519":
            guard let multibaseData = method.publicKeyMultibase else {
                throw CastorError.cannotRetrievePublicKeyFromDocument
            }
            return try apollo.createPublicKey(
                parameters: [
                    KeyProperties.type.rawValue: "EC",
                    KeyProperties.rawKey.rawValue: multibaseData,
                    KeyProperties.curve.rawValue: KnownKeyCurves.x25519.rawValue
                ])
        default:
            throw UnknownError.somethingWentWrongError(customMessage: nil, underlyingErrors: nil)
        }
    }
}
