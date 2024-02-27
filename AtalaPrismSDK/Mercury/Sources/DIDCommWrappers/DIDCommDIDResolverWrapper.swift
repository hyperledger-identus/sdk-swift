import Combine
import Core
import DIDCommSwift
import DIDCore
import Domain
import Foundation

class DIDCommDIDResolverWrapper {
    let logger: PrismLogger
    let castor: Castor
    var publisher = PassthroughSubject<Domain.DIDDocument, Error>()
    var cancellables = [AnyCancellable]()

    init(castor: Castor, logger: PrismLogger) {
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
            service.serviceEndpoint.map {
                return Service(
                    id: service.id,
                    type: service.type.first ?? "",
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
            verificationMethods: verificationMethods,
            authentication: authentications.map { .stringValue($0) },
            keyAgreement: keyAgreements.map { .stringValue($0) },
            services: services
        )
    }
}

extension Dictionary where Key == String, Value == String {
    func convertToJsonString() throws -> String? {
        try Core.convertToJsonString(dic: self)
    }
}
