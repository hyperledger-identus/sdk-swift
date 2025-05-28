import Core
import Domain
import Foundation

struct CreatePrismDIDOperation {
    private let method: DIDMethod = "prism"
    let apollo: Apollo
    let keys: [(KeyPurpose, PublicKey)]
    let services: [DIDDocument.Service]

    func compute() throws -> DID {
        var operation = Io_Iohk_Atala_Prism_Protos_AtalaOperation()
        guard keys.filter({ $0.0 == KeyPurpose.master }).count == 1 else {
            throw CastorError.requiresOneAndJustOneMasterKey
        }
        let groupByPurpose = Dictionary(grouping: keys, by: { $0.0 })
        operation.createDid = try createDIDAtalaOperation(
            publicKeys: groupByPurpose.flatMap { (key, value) in
                try value
                    .sorted(by: { $0.1.identifier < $1.1.identifier } )
                    .enumerated()
                    .map {
                        guard let curve = $0.element.1.getProperty(.curve) else {
                            throw CastorError.invalidPublicKeyCoding(didMethod: "prism", curve: "no curve")
                        }
                        return PrismDIDPublicKey(
                            apollo: apollo,
                            id: key.toPrismDIDKeyPurpose().id(index: $0.offset),
                            curve: curve,
                            usage: key.toPrismDIDKeyPurpose(),
                            keyData: $0.element.1
                        )
                    }
            },
            services: services
        )
        return try createLongFormFromOperation(method: method, atalaOperation: operation)
    }

    private func createDIDAtalaOperation(
        publicKeys: [PrismDIDPublicKey],
        services: [DIDDocument.Service]
    ) throws -> Io_Iohk_Atala_Prism_Protos_CreateDIDOperation {
        var didData = Io_Iohk_Atala_Prism_Protos_CreateDIDOperation.DIDCreationData()
        didData.publicKeys = try publicKeys.map { try $0.toProto() }
        didData.services = services.map {
            var service = Io_Iohk_Atala_Prism_Protos_Service()
            service.id = $0.id
            service.type = $0.type.first ?? ""
            service.serviceEndpoint = $0.serviceEndpoint.map { $0.uri }
            return service
        }

        var operation = Io_Iohk_Atala_Prism_Protos_CreateDIDOperation()
        operation.didData = didData
        return operation
    }

    private func createLongFormFromOperation(
        method: DIDMethod,
        atalaOperation: Io_Iohk_Atala_Prism_Protos_AtalaOperation
    ) throws -> DID {
        let encodedState = try atalaOperation.serializedData()
        let stateHash = encodedState.sha256()
        let base64State = encodedState.base64UrlEncodedString()
        let methodSpecificId = try PrismDIDMethodId(
            sections: [
                stateHash,
                base64State
            ]
        )
        return DID(method: method, methodId: methodSpecificId.description)
    }
}

extension KeyPurpose {
    func toPrismDIDKeyPurpose() -> PrismDIDPublicKey.Usage {
        switch self {
        case .master:
            return .masterKey
        case .issue:
            return .issuingKey
        case .authentication:
            return .authenticationKey
        case .capabilityDelegation:
            return .capabilityDelegationKey
        case .capabilityInvocation:
            return .capabilityInvocationKey
        case .agreement:
            return .keyAgreementKey
        case .revocation:
            return .revocationKey
        }
    }
}
