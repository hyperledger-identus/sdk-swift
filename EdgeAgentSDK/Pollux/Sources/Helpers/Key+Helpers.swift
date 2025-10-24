import Domain
import JSONWebAlgorithms
import JSONWebKey
import JSONWebSignature

func getHeaderForKey(key: JSONWebKey.JWK) throws -> JWSRegisteredFieldsHeader {
    let alg: SigningAlgorithm
    switch key.keyType {
    case .ellipticCurve:
        switch key.curve {
        case .secp256k1:
            alg = .ES256K
        case .p256:
            alg = .ES256
        case .p384:
            alg = .ES384
        case .p521:
            alg = .ES512
        default:
            throw ApolloError.invalidKeyCurve(invalid: key.curve?.rawValue ?? "", valid: ["secp256k1", "p256", "p364", "p512"])
        }
    case .octetKeyPair:
        switch key.curve {
        case .ed25519:
            alg = .EdDSA
        default:
            throw ApolloError.invalidKeyCurve(invalid: key.curve?.rawValue ?? "", valid: ["ed25519"])
        }
    case .rsa:
        alg = .RS256
    default:
        throw ApolloError.invalidKeyType(invalid: key.keyType.rawValue, valid: ["EC", "RSA"])
    }

    return DefaultJWSHeaderImpl(algorithm: alg)
}

