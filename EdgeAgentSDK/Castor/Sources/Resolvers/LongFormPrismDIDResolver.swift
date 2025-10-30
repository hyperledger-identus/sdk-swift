import Core
import Domain
import Foundation

struct LongFormPrismDIDResolver: DIDResolverDomain {
    enum KeyType {
        case master
        case issuing
        case authentication
        case agreement
        case capabilityDelegation
        case capabilityInvocation
        case revocation
        case unknown

        init(usage: PrismDIDPublicKey.Usage) {
            switch usage {
            case .masterKey:
                self = .master
            case .issuingKey:
                self = .issuing
            case .keyAgreementKey:
                self = .agreement
            case .capabilityDelegationKey:
                self = .capabilityDelegation
            case .capabilityInvocationKey:
                self = .capabilityInvocation
            case .authenticationKey:
                self = .authentication
            case .revocationKey:
                self = .revocation
            case .unknownKey:
                self = .unknown
            }
        }
    }
    struct PublicKeyDecoded {
        let id: String
        let keyType: KeyType
        let method: DIDDocument.VerificationMethod
    }
    let apollo: Apollo
    let logger: SDKLogger

    var method = "prism"

    func resolve(did: DID) throws -> DIDDocument {
        let prismDID = try LongFormPrismDID(did: did)
        guard
            let data = Data(fromBase64URL: prismDID.encodedState)
        else {
            logger.error(message: "The DID state hash doesn't match the state", metadata: [
                .maskedMetadataByLevel(key: "DID", value: did.string, level: .debug)
            ])
            throw CastorError.initialStateOfDIDChanged
        }

        let (verificationMethods, services) = try decodeState(
            did: did,
            stateHash: prismDID.stateHash,
            encodedData: data
        )

        let authenticates = verificationMethods.filter { $0.keyType == .authentication }.map {
            DIDDocument.Authentication(urls: [$0.id], verificationMethods: [])
        }

        let agreements = verificationMethods.filter { $0.keyType == .authentication }.map {
            DIDDocument.KeyAgreement(urls: [$0.id], verificationMethods: [])
        }

        let servicesProperty = DIDDocument.Services(values: services)

        let verificationMethodsProperty = DIDDocument.VerificationMethods(values: verificationMethods.map(\.method))

        let properties = [
            authenticates,
            agreements,
            servicesProperty,
            verificationMethodsProperty
        ].compactMap { $0 as? DIDDocumentCoreProperty }

        return DIDDocument(
            id: did,
            coreProperties: properties
        )
    }

    private func decodeState(
        did: DID,
        stateHash: String,
        encodedData: Data
    ) throws -> ([PublicKeyDecoded], [DIDDocument.Service]) {
        let verifyEncodedState = encodedData.sha256String()
        guard stateHash == verifyEncodedState else { throw CastorError.initialStateOfDIDChanged }
        let operation = try Io_Iohk_Atala_Prism_Protos_AtalaOperation(serializedData: encodedData)
        let publicKeys = try operation.createDid.didData.publicKeys.map {
            do {
                return try PrismDIDPublicKey(apollo: apollo, proto: $0)
            } catch {
                logger.error(message: "Failed to decode public key from document", metadata: [
                    .maskedMetadataByLevel(key: "DID", value: did.string, level: .debug)
                ])
                throw error
            }
        }

        let services = operation.createDid.didData.services.map {
            DIDDocument.Service(
                id: $0.id,
                type: .one($0.type),
                serviceEndpoint: .many($0.serviceEndpoint.map { .init(uri: $0) })
            )
        }
        let groupByPurpose = Dictionary(
            // Per specification master keys and revocation keys should not be in the did document
            grouping: publicKeys.filter { $0.usage != .masterKey && $0.usage != .revocationKey },
            by: { $0.usage }
        )
        let decodedPublicKeys = groupByPurpose.flatMap { (key, value) in
            value
                .sorted(by: { $0.id < $1.id } )
                .enumerated()
                .map {
                    let didUrl = DIDUrl(
                        did: did,
                        fragment: $0.element.usage.id(index: $0.offset)
                    )

                    let method = DIDDocument.VerificationMethod(
                        id: didUrl,
                        controller: did,
                        type: $0.element.keyData.getProperty(.curve) ?? "",
                        publicKeyMultibase: $0.element.keyData.raw.base64EncodedString()
                    )

                    return PublicKeyDecoded(
                        id: didUrl.string,
                        keyType: .init(usage: $0.element.usage),
                        method: method
                    )
                }
        }

        return (decodedPublicKeys, services)
    }
}
