import Domain
import Foundation
import JSONWebEncryption
import JSONWebKey

extension EdgeAgent {

    struct Backup: Codable {
        struct Key: Codable {
            let key: String
            let did: String?
            let index: Int?
            let recoveryId: String?
        }

        struct Credential: Codable {
            let data: String
            let recoveryId: String
        }

        struct Pair: Codable {
            let holder: String
            let recipient: String
            let alias: String?
        }

        struct DIDs: Codable {
            let did: String
            let alias: String?
        }

        struct Mediator: Codable {
            let mediatorDid: String
            let holderDid: String
            let routingDid: String
        }

        let keys: [Key]
        let linkSecret: String?
        let dids: [DIDs]
        let didPairs: [Pair]
        let credentials: [Credential]
        let messages: [String]
        let mediators: [Mediator]
    }

    /**
     Initiates the backup process for the wallet, encapsulating the wallet's essential data into a secure format.

     This method serializes the current state of the wallet, including keys, credentials, digital identity information (DIDs), message history, and mediator configurations into a structured JSON format. The output is then encrypted into a Json Web Encryption (JWE) format, ensuring the confidentiality and integrity of the backup data. The encryption uses the `secp256k1` elliptic curve digital signature algorithm, specifically the master key derived from the seed path `m'/0'/0'/0'`. This choice of encryption and key derivation ensures that the backup can be securely stored and, crucially, recovered, as long as the original seed used to initialize the wallet is available.

     - Returns: A `String` representation of the encrypted backup in JWE format. This string should be securely stored by the user, as it contains sensitive data crucial for wallet recovery.

     - Throws: An error if the backup process encounters any issues, including problems with data serialization, encryption, or internal wallet state inconsistencies.

     - Note: The backup's security is heavily dependent on the secrecy and strength of the seed used to initialize the wallet. Users must ensure that their seed is kept in a secure location and never shared.
     */
    public func backupWallet() async throws -> String {
        let backup = Backup(
            keys: try await backupKeys(),
            linkSecret: try await backupLinkSecret(),
            dids: try await backupDIDs(),
            didPairs: try await backupDIDPairs(),
            credentials: try await backupCredentials(),
            messages: try await backupMessages(),
            mediators: try await backupMediator()
        )

        let backupData = try JSONEncoder.didComm().encode(backup)

        let masterKey = try self.apollo.createPrivateKey(parameters: [
            KeyProperties.type.rawValue: "EC",
            KeyProperties.curve.rawValue: KnownKeyCurves.x25519.rawValue,
            KeyProperties.seed.rawValue: seed.value.base64Encoded(),
            KeyProperties.derivationPath.rawValue: DerivationPath().keyPathString()
        ])

        guard let exporting = masterKey.exporting else {
            throw EdgeAgentError.keyIsNotExportable
        }

        let jwk = try JSONEncoder.didComm().encode(exporting.jwk)
        let jwe = try JWE(
            payload: backupData,
            keyManagementAlg: .ecdhESA256KW,
            encryptionAlgorithm: .a256CBCHS512,
            recipientKey: try JSONDecoder().decode(JSONWebKey.JWK.self, from: jwk)
        ).compactSerialization

        return jwe
    }

    /**
     Recovers the wallet's state from a previously generated backup.

     This method takes an encrypted string in JWE format, which was produced by the `backupWallet` method, and decrypts it using the `secp256k1` master key. This master key is derived from the same seed path `m'/0'/0'/0'` used during the backup process, emphasizing the necessity of initializing the wallet with the same seed to ensure successful recovery. Once decrypted, the method reconstructs the wallet's state, including keys, digital identities (DIDs), credentials, and other stored information, from the JSON payload contained within the JWE.

     - Parameters:
       - encrypted: A `String` containing the encrypted backup data in JWE format. This data must be the output of a previous `backupWallet` operation and encrypted with the corresponding master key.

     - Returns: A void promise, indicating the completion of the recovery process. Upon successful completion, the wallet's state is restored to its condition at the time of the backup.

     - Throws: An error if the recovery process fails, which can occur due to issues like incorrect encryption details, failure to decrypt with the provided seed, or corruption of the backup data.

     - Note: The accuracy of the wallet recovery is entirely reliant on the backup being created and encrypted correctly, as well as the wallet being initialized with the same seed used during backup. Users must ensure that the seed and encrypted backup are securely stored and handled.
     */
    public func recoverWallet(encrypted: String) async throws {
        let masterKey = try self.apollo.createPrivateKey(parameters: [
            KeyProperties.type.rawValue: "EC",
            KeyProperties.curve.rawValue: KnownKeyCurves.x25519.rawValue,
            KeyProperties.seed.rawValue: seed.value.base64Encoded(),
            KeyProperties.derivationPath.rawValue: DerivationPath().keyPathString()
        ])

        guard let exporting = masterKey.exporting else {
            throw EdgeAgentError.keyIsNotExportable
        }

        let jwk = try JSONEncoder.didComm().encode(exporting.jwk)
        let backupData = try JWE(compactString: encrypted)
            .decrypt(recipientKey: try JSONDecoder.didComm().decode(JSONWebKey.JWK.self, from: jwk))

        let backup = try JSONDecoder.didComm().decode(Backup.self, from: backupData)

        try await recoverDidsWithKeys(dids: backup.dids, keys: backup.keys)
        try await recoverDIDPairs(pairs: backup.didPairs)
        try await recoverMessages(messages: backup.messages)
        try await recoverCredentials(credentials: backup.credentials)
        try await recoverMediators(mediators: backup.mediators)
        try await backup.linkSecret.asyncMap { try await recoverLinkSecret(secret: $0) }
    }

    func backupKeys() async throws -> [Backup.Key] {
        let dids = try await pluto.getAllDIDs()
            .first()
            .await()

        let backupDIDKeys = try await dids.asyncMap { did in
            try await did.privateKeys.asyncCompactMap { key -> Backup.Key? in
                guard let keyStr = try await keyToJWK(key: key, restoration: self.apollo) else {
                    return nil
                }
                return Backup.Key(
                    key: keyStr,
                    did: did.did.string,
                    index: key.index,
                    recoveryId: key.restorationIdentifier
                )
            }
        }.flatMap { $0 }

        let backupKeys = try await pluto.getAllKeys()
            .first()
            .await()
            .asyncCompactMap { key -> Backup.Key? in
                guard let keyStr = try await keyToJWK(key: key, restoration: self.apollo) else {
                    return nil
                }
                return Backup.Key(
                    key: keyStr,
                    did: nil,
                    index: key.index,
                    recoveryId: key.restorationIdentifier
                )
            }
        return backupKeys + backupDIDKeys
    }

    func recoverDidsWithKeys(dids: [Backup.DIDs], keys: [Backup.Key]) async throws {
        try await dids.asyncForEach { [weak self] did in
            let storableKeys = try await keys
                .filter {
                    let didurl = $0.did.flatMap { try? DIDUrl(string: $0) }?.did.string
                    return didurl == did.did
                }
                .compactMap { key in
                    return Data(base64URLEncoded: key.key).map { ($0, key.index) }
                }
                .asyncCompactMap {
                    guard let self else {
                        throw UnknownError.somethingWentWrongError(customMessage: nil, underlyingErrors: nil)
                    }
                    return try await jwkToKey(key: $0, restoration: self.apollo, index: $1)
                }

            try await self?.pluto.storeDID(
                did: DID(string: did.did),
                privateKeys: storableKeys,
                alias: did.alias
            )
            .first()
            .await()
        }
    }

    func recoverDIDPairs(pairs: [Backup.Pair]) async throws {
        try await pairs.asyncForEach { [weak self] in
            try await self?.pluto.storeDIDPair(pair: .init(
                holder: DID(string: $0.holder),
                other: DID(string: $0.recipient),
                name: $0.alias
            ))
            .first()
            .await()
        }
    }

    func recoverMessages(messages: [String]) async throws {
        let messages = messages.compactMap { messageStr -> (Message, Message.Direction)? in
            guard
                let messageData = Data(base64URLEncoded: messageStr),
                let message = try? JSONDecoder.backup().decode(Message.self, from: messageData)
            else {
                return nil
            }

            return (message, message.direction)
        }

        try await pluto.storeMessages(messages: messages).first().await()
    }

    func recoverCredentials(credentials: [Backup.Credential]) async throws {
        let downloader = DownloadDataWithResolver(castor: castor)
        let pollux = self.pollux
        let storableCredentials = try await credentials
            .asyncCompactMap { bakCredential -> StorableCredential? in
                guard
                    let data = Data(base64URLEncoded: bakCredential.data)
                else {
                    return nil
                }
                return try await pollux.importCredential(
                    credentialData: data,
                    restorationType: bakCredential.recoveryId,
                    options: [
                        .credentialDefinitionDownloader(downloader: downloader),
                        .schemaDownloader(downloader: downloader)
                    ]
                ).storable
            }
        try await self.pluto.storeCredentials(credentials: storableCredentials).first().await()
    }

    func recoverMediators(mediators: [Backup.Mediator]) async throws {
        try await mediators.asyncForEach { [weak self] in
            try await self?.pluto.storeMediator(
                peer: DID(string: $0.holderDid),
                routingDID: DID(string: $0.routingDid),
                mediatorDID: DID(string: $0.mediatorDid)
            )
            .first()
            .await()
        }
    }

    func recoverLinkSecret(secret: String) async throws {
        struct LinkSecretStorableKey: StorableKey {
            var identifier = "linkSecret"
            let index: Int? = nil
            let queryDerivationPath: String? = nil
            let storableData: Data
            let restorationIdentifier = "linkSecret+key"
        }

        try await pluto.storeLinkSecret(secret: LinkSecretStorableKey(storableData: try secret.tryToData()))
            .first()
            .await()
    }

    func backupDIDs() async throws -> [Backup.DIDs] {
        let dids = try await pluto.getAllDIDs()
            .first()
            .await()

        return dids.map {
            return Backup.DIDs(
                did: $0.did.string,
                alias: $0.alias
            )
        }
    }

    func backupDIDPairs() async throws -> [Backup.Pair] {
        return try await pluto.getAllDidPairs()
            .first()
            .await()
            .map {
                Backup.Pair(holder: $0.holder.string, recipient: $0.other.string, alias: $0.name)
            }
    }

    func backupLinkSecret() async throws -> String {
        guard let linkSecret = try await pluto.getLinkSecret().first().await()?.storableData.tryToString() else {
            throw EdgeAgentError.noLinkSecretConfigured
        }
        return linkSecret
    }

    func backupCredentials() async throws -> [Backup.Credential] {
        let pollux = self.pollux
        return try await pluto
            .getAllCredentials()
            .tryMap {
                $0.compactMap {
                    try? pollux.restoreCredential(
                        restorationIdentifier: $0.recoveryId,
                        credentialData: $0.credentialData
                    )
                }.compactMap { $0.exportable }
            }
            .first()
            .await()
            .map {
                Backup.Credential(
                    data: $0.exporting.base64UrlEncodedString(),
                    recoveryId: $0.restorationType
                )
            }

    }

    func backupMessages() async throws -> [String] {
        try await pluto.getAllMessages()
            .first()
            .await()
            .compactMap {
                return try JSONEncoder.backup().encode($0).base64UrlEncodedString()
            }
    }

    func backupMediator() async throws -> [Backup.Mediator] {
        try await pluto.getAllMediators()
            .first()
            .await()
            .map {
                Backup.Mediator(
                    mediatorDid: $0.mediatorDID.string,
                    holderDid: $0.did.string,
                    routingDid: $0.routingDID.string
                )
            }
    }
}

private func keyToJWK(key: StorableKey, restoration: KeyRestoration) async throws -> String? {
    let key = try await restoration.restoreKey(key)
    guard let exportable = key.exporting else {
        return nil
    }
    return try JSONEncoder().encode(exportable.jwk).base64UrlEncodedString()
}

private func jwkToKey(key: Data, restoration: KeyRestoration, index: Int?) async throws -> StorableKey? {
    let jwk = try JSONDecoder().decode(Domain.JWK.self, from: key)
    let key = try await restoration.restoreKey(jwk, index: index)
    return key.storable
}
