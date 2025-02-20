import Foundation

public enum KeyPurpose: String, Hashable, Equatable, CaseIterable {
    case master
    case issue
    case capabilityDelegation
    case capabilityInvocation
    case authentication
    case revocation
    case agreement
}

/// The Castor protocol defines the set of decentralized identifier (DID) operations that are used in the Atala PRISM architecture. It provides a way for users to create, manage, and control their DIDs and associated cryptographic keys.
public protocol Castor {
    /// parseDID parses a string representation of a Decentralized Identifier (DID) into a DID object. This function may throw an error if the string is not a valid DID.
    ///
    /// - Parameter str: The string representation of the DID
    /// - Returns: The DID object
    /// - Throws: An error if the string is not a valid DID
    func parseDID(str: String) throws -> DID
    
    /// createDID creates a DID for a method using a given an array of public keys and list of services. This function may throw an error.
    /// - Parameters:
    ///   - method: DID Method to use (ex: prism, peer)
    ///   - keys: An array of Tuples with the public key and the key purpose
    ///   - services: The list of services
    /// - Returns: The created DID
    func createDID(
        method: DIDMethod,
        keys: [(KeyPurpose, PublicKey)],
        services: [DIDDocument.Service]
    ) throws -> DID

    /// createPrismDID creates a DID for a prism (a device or server that acts as a DID owner and controller) using a given master public key and list of services. This function may throw an error if the master public key or services are invalid.
    ///
    /// - Parameters:
    ///   - masterPublicKey: The master public key of the prism
    ///   - services: The list of services offered by the prism
    /// - Returns: The DID of the prism
    /// - Throws: An error if the master public key or services are invalid
    func createPrismDID(
        masterPublicKey: PublicKey,
        services: [DIDDocument.Service]
    ) throws -> DID

    /// createPeerDID creates a DID for a peer (a device or server that acts as a DID subject) using given key agreement and authentication key pairs and a list of services. This function may throw an error if the key pairs or services are invalid.
    ///
    /// - Parameters:
    ///   - keyAgreementKeyPair: The key pair used for key agreement (establishing secure communication between peers)
    ///   - authenticationKeyPair: The key pair used for authentication (verifying the identity of a peer)
    ///   - services: The list of services offered by the peer
    /// - Returns: The DID of the peer
    /// - Throws: An error if the key pairs or services are invalid
    func createPeerDID(
        keyAgreementPublicKey: PublicKey,
        authenticationPublicKey: PublicKey,
        services: [DIDDocument.Service]
    ) throws -> DID

    /// resolveDID asynchronously resolves a DID to its corresponding DID Document. This function may throw an error if the DID is invalid or the document cannot be retrieved.
    ///
    /// - Parameter did: The DID to resolve
    /// - Returns: The DID Document associated with the DID
    /// - Throws: An error if the DID is invalid or the document cannot be retrieved
    func resolveDID(did: DID) async throws -> DIDDocument

    /// verifySignature asynchronously verifies the authenticity of a signature using the corresponding DID, challenge, and signature data. This function returns a boolean value indicating whether the signature is valid or not. This function may throw an error if the DID or signature data are invalid.
    ///
    /// - Parameters:
    ///   - did: The DID associated with the signature
    ///   - challenge: The challenge used to generate the signature
    ///   - signature: The signature data to verify
    /// - Returns: A boolean value indicating whether the signature is valid or not
    /// - Throws: An error if the DID or signature data are invalid
    func verifySignature(
        did: DID,
        challenge: Data,
        signature: Data
    ) async throws -> Bool

    /// verifySignature verifies the authenticity of a signature using the corresponding DID Document, challenge, and signature data. This function returns a boolean value indicating whether the signature is valid or not. This function may throw an error if the DID Document or signature data are invalid.
    ///
    /// - Parameters:
    ///   - document: The DID Document associated with the signature
    ///   - challenge: The challenge used to generate the signature
    ///   - signature: The signature data to verify
    /// - Returns: A boolean value indicating whether the signature is valid or not
    /// - Throws: An error if the DID Document or signature data are invalid
    func verifySignature(
        document: DIDDocument,
        challenge: Data,
        signature: Data
    ) async throws -> Bool

    /// Retrieves the public keys associated with a specific decentralized identifier (DID).
    ///
    /// - Parameter did: The decentralized identifier (DID) whose public keys are to be retrieved.
    /// - Returns: An array of `PublicKey` objects associated with the given DID.
    /// - Throws: An error if the retrieval process fails.
    func getDIDPublicKeys(did: DID) async throws -> [PublicKey]
}

extension Castor {
    func createPrismDID(
        masterPublicKey: PublicKey,
        services: [DIDDocument.Service] = []
    ) throws -> DID {
        try createPrismDID(masterPublicKey: masterPublicKey, services: services)
    }
}
