import Domain
import Foundation
import Pluto

class KeychainMock: KeychainStore, KeychainProvider {
    var keys: [String: KeychainStorableKey] = [:]
    
    func getKey(
        service: String,
        account: String,
        tag: String?,
        algorithm: KeychainStorableKeyProperties.KeyAlgorithm,
        type: KeychainStorableKeyProperties.KeyType
    ) throws -> Data {
        guard let key = keys[service+account] else {
            throw PlutoError.errorRetrivingKeyFromKeychainKeyNotFound(service: service, account: account, applicationLabel: tag)
        }
        return key.storableData
    }
    
    func addKey(
        _ key: KeychainStorableKey,
        service: String,
        account: String
    ) throws {
        keys[service+account] = key
    }
}
