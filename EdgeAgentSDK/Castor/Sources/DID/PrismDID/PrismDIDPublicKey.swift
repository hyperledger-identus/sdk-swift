import Domain
import Foundation

struct PrismDIDPublicKey {
    enum Usage: String {
        case masterKey
        case issuingKey
        case keyAgreementKey
        case capabilityDelegationKey
        case capabilityInvocationKey
        case authenticationKey
        case revocationKey
        case unknownKey

        var defaultId: String {
            id(index: 0)
        }

        func toProto() -> Io_Iohk_Atala_Prism_Protos_KeyUsage {
            switch self {
            case .masterKey:
                return .masterKey
            case .issuingKey:
                return .issuingKey
            case .capabilityInvocationKey:
                return .capabilityInvocationKey
            case .capabilityDelegationKey:
                return .capabilityDelegationKey
            case .authenticationKey:
                return .authenticationKey
            case .revocationKey:
                return .revocationKey
            case .keyAgreementKey:
                return .keyAgreementKey
            case .unknownKey:
                return .unknownKey
            }
        }

        func id(index: Int) -> String {
            switch self {
            case .masterKey:
                return "master\(index)"
            case .issuingKey:
                return "issuing\(index)"
            case .capabilityDelegationKey:
                return "capability-delegationKey\(index)"
            case .capabilityInvocationKey:
                return "capability-invocationKey\(index)"
            case .authenticationKey:
                return "authentication\(index)"
            case .revocationKey:
                return "revocation\(index)"
            case .keyAgreementKey:
                return "key-agreement\(index)"
            case .unknownKey:
                return "unknown\(index)"
            }
        }
    }

    let apollo: Apollo
    let id: String
    let curve: String
    let usage: Usage
    let keyData: PublicKey

    init(apollo: Apollo, id: String, curve: String, usage: Usage, keyData: PublicKey) {
        self.apollo = apollo
        self.id = id
        self.curve = curve
        self.usage = usage
        self.keyData = keyData
    }

    init(apollo: Apollo, proto: Io_Iohk_Atala_Prism_Protos_PublicKey) throws {
        self.apollo = apollo
        id = proto.id
        usage = proto.usage.fromProto()
        switch proto.keyData {
        case let .ecKeyData(value):
            curve = value.curve.lowercased()
            keyData = try apollo.createPublicKey(parameters: [
                KeyProperties.type.rawValue: "EC",
                KeyProperties.curve.rawValue: value.curve.lowercased(),
                KeyProperties.curvePointX.rawValue: value.x.base64EncodedString(),
                KeyProperties.curvePointY.rawValue: value.y.base64EncodedString()
            ])
        case let .compressedEcKeyData(value):
            curve = value.curve.lowercased()
            keyData = try apollo.createPublicKey(parameters: [
                KeyProperties.type.rawValue: "EC",
                KeyProperties.curve.rawValue: value.curve.lowercased(),
                KeyProperties.rawKey.rawValue: value.data.base64EncodedString()
            ])
        default:
            throw CastorError.invalidPublicKeyCoding(didMethod: "prism", curve: "")
        }
    }

    func toProto() throws -> Io_Iohk_Atala_Prism_Protos_PublicKey {
        var protoKey = Io_Iohk_Atala_Prism_Protos_PublicKey()
        protoKey.id = id
        protoKey.usage = usage.toProto()
        switch curve {
        case "Ed25519", "X25519":
            var protoEC = Io_Iohk_Atala_Prism_Protos_CompressedECKeyData()
            protoEC.data = keyData.raw
            protoEC.curve = curve
            protoKey.keyData = .compressedEcKeyData(protoEC)
        case "secp256k1":
            guard
                let pointXStr = keyData.getProperty(.curvePointX),
                let pointYStr = keyData.getProperty(.curvePointY),
                let pointX = Data(base64URLEncoded: pointXStr),
                let pointY = Data(base64URLEncoded: pointYStr)
            else {
                throw ApolloError.missingKeyParameters(missing: [
                    KeyProperties.curvePointX.rawValue,
                    KeyProperties.curvePointY.rawValue
                ])
            }
            var protoEC = Io_Iohk_Atala_Prism_Protos_ECKeyData()
            protoEC.x = pointX
            protoEC.y = pointY
            protoEC.curve = curve
            protoKey.keyData = .ecKeyData(protoEC)
        default:
            throw ApolloError.missingKeyParameters(missing: [
                KeyProperties.curvePointY.rawValue
            ])
        }
        return protoKey
    }
}

private extension Io_Iohk_Atala_Prism_Protos_KeyUsage {
    func fromProto() -> PrismDIDPublicKey.Usage {
        switch self {
        case .masterKey:
            return .masterKey
        case .unknownKey:
            return .unknownKey
        case .issuingKey:
            return .issuingKey
        case .capabilityInvocationKey:
            return .capabilityInvocationKey
        case .capabilityDelegationKey:
            return .capabilityDelegationKey
        case .authenticationKey:
            return .authenticationKey
        case .revocationKey:
            return .revocationKey
        case .keyAgreementKey:
            return .keyAgreementKey
        case .UNRECOGNIZED:
            return .unknownKey
        }
    }
}
