import Combine
import Domain
import Foundation

// MARK: DID High Level functionalities
public extension OIDCAgent {

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
        try await edgeAgent.createNewPrismDID(
            keys: [],
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
}
