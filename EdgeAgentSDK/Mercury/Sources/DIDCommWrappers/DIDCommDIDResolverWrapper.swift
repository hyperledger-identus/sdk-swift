import Combine
import Core
import DIDCommSwift
import DIDCore
import Domain
import Foundation

class DIDCommDIDResolverWrapper {
    let logger: SDKLogger
    let castor: Castor
    var publisher = PassthroughSubject<Domain.DIDDocument, Error>()
    var cancellables = [AnyCancellable]()

    init(castor: Castor, logger: SDKLogger) {
        self.castor = castor
        self.logger = logger
    }

    fileprivate func resolve(did: String) {
        Task { [weak self] in
            let document = try await self?.castor.resolveDID(did: DID(string: did))
            document.map { self?.publisher.send($0) }
        }
    }
}

extension DIDCommDIDResolverWrapper: DIDResolver {
    func resolve(did: DIDCore.DID) async throws -> DIDCore.DIDDocument {
        let document = try await castor.resolveDID(did: DID(string: did.description))
        return try .init(from: document)
    }
}

extension DIDCore.DIDDocument {
    init(from: Domain.DIDDocument) throws {
        var authentications = [String]()
        var keyAgreements = [String]()
        let verificationMethods: [VerificationMethod] = try from.verificationMethods.compactMap {
            switch KnownVerificationMaterialType(rawValue: $0.type) {
            case .agreement:
                keyAgreements.append($0.id.string)
            case .authentication:
                authentications.append($0.id.string)
            default:
                return nil
            }

            if
                let jsonKeys = try $0.publicKeyJwk?.convertToJsonString()
            {
                return .init(
                    id: $0.id.string,
                    controller: $0.controller.string,
                    type: $0.type,
                    material: try .fromJWK(jwk: JSONDecoder().decode(JWK.self, from: jsonKeys.tryToData()))
                )
            } else if let multibase = $0.publicKeyMultibase {
                return .init(
                    id: $0.id.string,
                    controller: $0.controller.string,
                    type: $0.type,
                    material: .init(format: .multibase, value: try multibase.tryToData())
                )
            } else {
                return nil
            }
        }

        let services = from.services.flatMap { service in
            service.serviceEndpoint.array.map {
                return Service(
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
            verificationMethod: verificationMethods,
            authentication: authentications.map { .stringValue($0) },
            keyAgreement: keyAgreements.map { .stringValue($0) },
            services: services.map { $0.toAnyCodable() }
        )
    }
}

extension Dictionary where Key == String, Value == String {
    func convertToJsonString() throws -> String? {
        try Core.convertToJsonString(dic: self)
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
                serviceEndpoint: AnyCodable(value)
            )
        case let value as [String: Any]:
            self = .init(
                id: id,
                type: type,
                serviceEndpoint: AnyCodable(value)
            )
        case let value as [String]:
            self = .init(
                id: id,
                type: type,
                serviceEndpoint: AnyCodable(value)
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
