import Core
import DIDCore
import Domain
import Foundation
import Multibase
import PeerDID

struct CreatePeerDIDOperation {
    private let method: DIDMethod = "peer"
    let keys: [(KeyPurpose, PublicKey)]
    let services: [Domain.DIDDocument.Service]

    func compute() throws -> Domain.DID {
        let authenticationKeys = try keys
            .filter { $0.0 == .authentication }
            .map(\.1)
            .map(authenticationFromPublicKey(publicKey:))
        let agreementKeys = try keys
            .filter { $0.0 == .agreement }
            .map(\.1)
            .map(keyAgreementFromPublicKey(publicKey:))
        let did = try PeerDIDHelper.createAlgo2(
            authenticationKeys: authenticationKeys,
            agreementKeys: agreementKeys,
            services: services.flatMap { service in
                service.serviceEndpoint.array.map {
                    AnyCodable(dictionaryLiteral:
                        ("id", service.id ?? ""),
                        ("type", service.type.array.first ?? ""),
                        ("serviceEndpoint", [
                            "uri" : $0.uri,
                            "accept" : $0.accept,
                            "routing_keys" : $0.routingKeys
                        ])
                    )
                }
            }
        )
        return try .init(string: did.string)
    }

    private func keyAgreementFromPublicKey(publicKey: PublicKey) throws -> PeerDIDVerificationMaterial {
        guard
            publicKey.getProperty(.curve)?.lowercased() == KnownKeyCurves.x25519.rawValue
        else { throw CastorError.invalidPublicKeyCoding(didMethod: "peer", curve: KnownKeyCurves.x25519.rawValue) }
        return try .init(
            format: .jwk,
            key: publicKey.raw,
            type: .agreement(.jsonWebKey2020)
        )
    }

    private func authenticationFromPublicKey(publicKey: PublicKey) throws -> PeerDIDVerificationMaterial {
        guard
            publicKey.getProperty(.curve)?.lowercased() == KnownKeyCurves.ed25519.rawValue
        else {
            throw CastorError.invalidPublicKeyCoding(
                didMethod: "peer",
                curve: KnownKeyCurves.ed25519.rawValue
            )
        }

        return try .init(
            format: .jwk,
            key: publicKey.raw,
            type: .authentication(.jsonWebKey2020)
        )
    }
}
