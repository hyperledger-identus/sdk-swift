import DIDCore
import Domain
import Foundation
import PeerDID

struct PeerDIDResolver: DIDResolverDomain {
    var method = "peer"

    func resolve(did: Domain.DID) async throws -> Domain.DIDDocument {
        try PeerDIDHelper.resolve(peerDIDStr: did.string).toDomain()
    }
}

extension DIDCore.DIDDocument {

    init(from: Domain.DIDDocument) throws {
        let verificationMethods = try from.verificationMethods.map {
            try DIDCore.DIDDocument.VerificationMethod(from: $0)
        }
        let verificationMethodsIds = verificationMethods.map(\.id)

        let authenticationMethods = try from.authenticate
            .filter {
                verificationMethodsIds.contains($0.id.string)
            }
            .map {
                try DIDCore.DIDDocument.VerificationMethod(from: $0)
            }
        let authenticationIds = from.authenticate.map(\.id.string)

        let keyAgreementMethods = try from.keyAgreement
            .filter {
                verificationMethodsIds.contains($0.id.string)
            }
            .map {
                try DIDCore.DIDDocument.VerificationMethod(from: $0)
            }

        let keyAgreementIds = from.keyAgreement.map(\.id.string)

        let services = from.services.flatMap { service in
            service.serviceEndpoint.array.map {
                DIDCore.DIDDocument.Service(
                    id: service.id ?? "",
                    type: service.type.array.first ?? "",
                    serviceEndpoint: AnyCodable(
                        dictionaryLiteral:
                            ("uri", $0.uri),
                            ("accept", $0.accept),
                            ("routing_keys", $0.routingKeys)
                    )
                )
            }
        }

        self.init(
            id: from.id.string,
            verificationMethod: verificationMethods + authenticationMethods + keyAgreementMethods,
            authentication: authenticationIds.map { .stringValue($0) },
            assertionMethod: nil,
            capabilityDelegation: nil,
            keyAgreement: keyAgreementIds.map { .stringValue($0) },
            services: services.map { $0.toAnyCodable() }
        )
    }

    func toDomain() throws -> Domain.DIDDocument {
        let authenticationUrls = self.verificationMethod?
            .filter {
                guard let type = KnownVerificationMaterialType(rawValue: $0.type) else {
                    return false
                }
                switch type {
                case .authentication:
                    return true
                default:
                    return false
                }
            }
            .map { $0.id } ?? []

        let keyAgreementUrls = self.verificationMethod?
            .filter {
                guard let type = KnownVerificationMaterialType(rawValue: $0.type) else {
                    return false
                }
                switch type {
                case .agreement:
                    return true
                default:
                    return false
                }
            }
            .map { $0.id } ?? []

        let verificationMethods = try self.verificationMethod?.map {
            try $0.toDomain()
        } ?? []

        let services = try self.services?.map {
            let service = try DIDCore.DIDDocument.Service(from: $0)
            switch service.serviceEndpoint.value {
            case let endpoint as [String: Any]:
                guard
                    let uri = endpoint["uri"] as? String
                else {
                    throw CastorError.notPossibleToResolveDID(did: service.id, reason: "Invalid service")
                }
                return Domain.DIDDocument.Service(
                    id: service.id,
                    type: .one(service.type),
                    serviceEndpoint: .one(
                        .init(
                            uri: uri,
                            accept: endpoint["accept"] as? [String] ?? [],
                            routingKeys: endpoint["routing_keys"] as? [String] ?? []
                        )
                    )
                )
            case let endpoint as String:
                return Domain.DIDDocument.Service(
                    id: service.id,
                    type: .one(service.type),
                    serviceEndpoint: .one(
                        .init(
                            uri: endpoint,
                            accept: ($0.value as? [String: Any])?["accept"] as? [String] ?? [],
                            routingKeys: ($0.value as? [String: Any])?["routing_keys"] as? [String] ?? []
                        )
                    )
                )
            default:
                throw CastorError.notPossibleToResolveDID(did: service.id, reason: "Invalid service")
            }
        } ?? [Domain.DIDDocument.Service]()

        return Domain.DIDDocument(
            id: try DID(string: self.id),
            coreProperties: [
                Domain.DIDDocument.Authentication(
                    urls: authenticationUrls,
                    verificationMethods: []
                ),
                Domain.DIDDocument.KeyAgreement(
                    urls: keyAgreementUrls,
                    verificationMethods: []
                ),
                Domain.DIDDocument.VerificationMethods(values: verificationMethods),
                Domain.DIDDocument.Services(values: services)
            ]
        )
    }
}

extension DIDCore.DIDDocument.VerificationMethod {

    init(from: Domain.DIDDocument.VerificationMethod) throws {
        if let publicKeyMultibase = from.publicKeyMultibase {
            self.init(
                id: from.id.string,
                controller: from.controller.string,
                type: from.type,
                material: .init(
                    format: .multibase,
                    value: try publicKeyMultibase.tryData(using: .utf8)
                )
            )
        } else if let publicKeyJwk = from.publicKeyJwk {
            self.init(
                id: from.id.string,
                controller: from.controller.string,
                type: from.type,
                material: .init(
                    format: .jwk,
                    value: try JSONSerialization.data(withJSONObject: publicKeyJwk)
                )
            )
        } else {
            throw PeerDIDError.invalidMaterialType("")
        }
    }

    func toDomain() throws -> Domain.DIDDocument.VerificationMethod {
        switch material.format {
        case .jwk:
            return Domain.DIDDocument.VerificationMethod(
                id: try DIDUrl(string: id),
                controller: try DID(string: controller),
                type: type,
                publicKeyJwk: try JSONSerialization.jsonObject(with: material.value) as? [String: String]
            )
        case .multibase:
            return Domain.DIDDocument.VerificationMethod(
                id: try DIDUrl(string: id),
                controller: try DID(string: controller),
                type: type,
                publicKeyMultibase: String(data: material.value, encoding: .utf8)
            )
        default:
            throw CastorError.notPossibleToResolveDID(did: id, reason: "Invalid did peer")
        }
    }
}

extension DIDCore.DIDDocument.Service {
    init(from: DIDCore.AnyCodable) throws {
        guard
            let dic = from.value as? [String: Any],
            let id = dic["id"] as? String,
            let type = dic["type"] as? String,
            let serviceEndpoint = dic["serviceEndpoint"]
        else { throw CommonError.invalidCoding(message: "Could not decode service") }
        switch serviceEndpoint {
        case let value as DIDCore.AnyCodable:
            self = .init(
                id: id,
                type: type,
                serviceEndpoint: value
            )
        case let value as String:
            self = .init(
                id: id,
                type: type,
                serviceEndpoint: DIDCore.AnyCodable(value)
            )
        case let value as [String: Any]:
            self = .init(
                id: id,
                type: type,
                serviceEndpoint: DIDCore.AnyCodable(value)
            )
        case let value as [String]:
            self = .init(
                id: id,
                type: type,
                serviceEndpoint: DIDCore.AnyCodable(value)
            )
        default:
            throw CommonError.invalidCoding(message: "Could not decode service")
        }
    }

    func toAnyCodable() -> DIDCore.AnyCodable {
        AnyCodable(dictionaryLiteral:
            ("id", self.id),
            ("type", self.type),
            ("serviceEndpoint", self.serviceEndpoint.value)
        )
    }
}
