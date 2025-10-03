import Domain
import Foundation
import JSONWebKey

extension Domain.JWK {
    public init(from: JSONWebKey.JWK) throws {
        let asJson = try JSONEncoder().encode(from)
        self = try JSONDecoder().decode(Self.self, from: asJson)
    }

    public func toJoseJWK() throws -> JSONWebKey.JWK {
        let asJson = try JSONEncoder().encode(self)
        return try JSONDecoder().decode(JSONWebKey.JWK.self, from: asJson)
    }
}
