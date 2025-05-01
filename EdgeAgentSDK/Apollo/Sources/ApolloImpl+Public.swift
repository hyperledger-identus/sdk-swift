import ApolloLibrary
import Domain
import Foundation

extension ApolloImpl: Apollo {
    /// createRandomMnemonics creates a random set of mnemonic phrases that can be used as a seed for generating a private key.
    ///
    /// - Returns: An array of mnemonic phrases
    public func createRandomMnemonics() -> [String] {
        RandomMnemonicsOperation(logger: ApolloImpl.logger).compute()
    }

    /// createSeed takes in a set of mnemonics and a passphrase, and returns a seed object used to generate a private key.
    /// This function may throw an error if the mnemonics or passphrase are invalid.
    ///
    /// - Parameters:
    ///   - mnemonics: An array of mnemonic phrases
    ///   - passphrase: A passphrase used to enhance the security of the seed
    /// - Returns: A seed object
    /// - Throws: An error if the mnemonics or passphrase are invalid
    public func createSeed(mnemonics: [String], passphrase: String) throws -> Seed {
        try CreateSeedOperation(logger: ApolloImpl.logger, words: mnemonics, passphrase: passphrase).compute()
    }

    /// createRandomSeed creates a random seed and a corresponding set of mnemonic phrases.
    ///
    /// - Returns: A tuple containing an array of mnemonic phrases and a seed object
    public func createRandomSeed() -> (mnemonic: [String], seed: Seed) {
        let words = ApolloLibrary
            .Mnemonic
            .companion
            .createRandomMnemonics()
        guard let seed = try? ApolloLibrary
            .Mnemonic
            .companion
            .createSeed(mnemonics: words, passphrase: "AtalaPrism")
        else {
            fatalError("This should never happen")
        }
        return (words, Seed(value: seed.toData()))
    }

    public func createPrivateKey(parameters: [String : String]) throws -> PrivateKey {
        guard
            let keyType = parameters[KeyProperties.type.rawValue]
        else { throw ApolloError.invalidKeyType(invalid: "", valid: ValidCryptographicTypes.allCases.map(\.rawValue)) }
        let identifier = parameters[KeyProperties.kid.rawValue] ?? UUID().uuidString
        switch keyType {
        case ValidCryptographicTypes.ec.rawValue:
            guard
                let curveStr = parameters[KeyProperties.curve.rawValue],
                let curve = ValidECCurves(rawValue: curveStr)
            else {
                throw ApolloError.invalidKeyCurve(
                    invalid: parameters[KeyProperties.curve.rawValue] ?? "",
                    valid: ValidECCurves.allCases.map(\.rawValue)
                )
            }
            switch curve {
            case .secp256k1:
                if
                    let keyData = parameters[KeyProperties.rawKey.rawValue].flatMap({ Data(base64Encoded: $0) })
                {
                    let derivationPath = try parameters[KeyProperties.derivationPath.rawValue].map {
                        try DerivationPath(string: $0)
                    } ?? DerivationPath()
                    return Secp256k1PrivateKey(
                        identifier: identifier,
                        raw: keyData,
                        derivationPath: derivationPath
                    )
                } else {
                    guard
                        let derivationPathStr = parameters[KeyProperties.derivationPath.rawValue],
                        let seedStr = parameters[KeyProperties.seed.rawValue],
                        let seed = Data(base64Encoded: seedStr)
                    else {
                        throw ApolloError.missingKeyParameters(missing: [
                            KeyProperties.derivationPath.rawValue, KeyProperties.seed.rawValue
                        ])
                    }
                    let derivationPath = try DerivationPath(string: derivationPathStr)
                    return try CreateSec256k1KeyPairOperation().compute(
                        identifier: identifier,
                        seed: Seed(value: seed),
                        keyPath: derivationPath
                    )
                }
            case .ed25519:
                if
                    let keyStr = parameters[KeyProperties.rawKey.rawValue],
                    let keyData = Data(base64Encoded: keyStr)
                {
                    return try CreateEd25519KeyPairOperation(logger: ApolloImpl.logger).compute(
                        identifier: identifier,
                        fromPrivateKey: keyData
                    )
                } else if
                    let derivationPathStr = parameters[KeyProperties.derivationPath.rawValue],
                    let seedStr = parameters[KeyProperties.seed.rawValue],
                    let seed = Data(base64Encoded: seedStr)
                {
                    let derivationPath = try DerivationPath(string: derivationPathStr)
                    return try CreateEd25519KeyPairOperation(logger: ApolloImpl.logger).compute(
                        identifier: identifier,
                        seed: Seed(value: seed),
                        keyPath: derivationPath
                    )
                }
                return CreateEd25519KeyPairOperation(logger: ApolloImpl.logger).compute(identifier: identifier)
            case .x25519:
                if
                    let keyStr = parameters[KeyProperties.rawKey.rawValue],
                    let keyData = Data(base64Encoded: keyStr)
                {
                    return try CreateX25519KeyPairOperation(logger: ApolloImpl.logger).compute(
                        identifier: identifier,
                        fromPrivateKey: keyData
                    )
                }  else if
                    let derivationPathStr = parameters[KeyProperties.derivationPath.rawValue],
                    let seedStr = parameters[KeyProperties.seed.rawValue],
                    let seed = Data(base64Encoded: seedStr)
                {
                    let derivationPath = try DerivationPath(string: derivationPathStr)
                    return try CreateX25519KeyPairOperation(logger: ApolloImpl.logger).compute(
                        identifier: identifier,
                        seed: Seed(value: seed),
                        keyPath: derivationPath
                    )
                }
                return CreateX25519KeyPairOperation(logger: ApolloImpl.logger).compute(identifier: identifier)
            }
        default:
            throw ApolloError.invalidKeyType(invalid: keyType, valid: ValidCryptographicTypes.allCases.map(\.rawValue))
        }
    }

    public func createPublicKey(parameters: [String : String]) throws -> PublicKey {
        guard
            let keyType = parameters[KeyProperties.type.rawValue]
        else { throw ApolloError.invalidKeyType(invalid: "", valid: ValidCryptographicTypes.allCases.map(\.rawValue)) }
        let identifier = parameters[KeyProperties.kid.rawValue] ?? UUID().uuidString
        switch keyType {
        case ValidCryptographicTypes.ec.rawValue:
            guard
                let curveStr = parameters[KeyProperties.curve.rawValue],
                let curve = ValidECCurves(rawValue: curveStr.lowercased())
            else {
                throw ApolloError.invalidKeyCurve(
                    invalid: parameters[KeyProperties.curve.rawValue] ?? "",
                    valid: ValidECCurves.allCases.map(\.rawValue)
                )
            }
            switch curve {
            case .secp256k1:
                if let keyData = parameters[KeyProperties.rawKey.rawValue].flatMap({ Data(base64Encoded: $0) }) {
                    return Secp256k1PublicKey(identifier: identifier, raw: keyData)
                } else if
                    let x = parameters[KeyProperties.curvePointX.rawValue].flatMap({ Data(base64Encoded: $0) }),
                    let y = parameters[KeyProperties.curvePointY.rawValue].flatMap({ Data(base64Encoded: $0) })
                {
                    return Secp256k1PublicKey(identifier: identifier, x: x, y: y)
                } else {
                    throw ApolloError.missingKeyParameters(missing: [
                        KeyProperties.rawKey.rawValue,
                        KeyProperties.curvePointX.rawValue,
                        KeyProperties.curvePointY.rawValue
                    ])
                }
            case .ed25519:
                guard
                    let keyData = parameters[KeyProperties.rawKey.rawValue].flatMap({ Data(base64Encoded: $0) })
                else {
                    throw ApolloError.missingKeyParameters(missing: [KeyProperties.rawKey.rawValue])
                }
                return Ed25519PublicKey(identifier: identifier, raw: keyData)
            case .x25519:
                guard
                    let keyData = parameters[KeyProperties.rawKey.rawValue].flatMap({ Data(base64Encoded: $0) })
                else {
                    throw ApolloError.missingKeyParameters(missing: [KeyProperties.rawKey.rawValue])
                }
                return X25519PublicKey(identifier: identifier, raw: keyData)
            }
        case ValidCryptographicTypes.okp.rawValue:
            guard
                let curveStr = parameters[KeyProperties.curve.rawValue],
                let curve = ValidOKPCurves(rawValue: curveStr.lowercased())
            else {
                throw ApolloError.invalidKeyCurve(
                    invalid: parameters[KeyProperties.curve.rawValue] ?? "",
                    valid: ValidOKPCurves.allCases.map(\.rawValue)
                )
            }
            switch curve {
            case .ed25519:
                guard
                    let keyData = parameters[KeyProperties.rawKey.rawValue].flatMap({ Data(base64Encoded: $0) })
                else {
                    guard
                        let keyData = parameters[KeyProperties.curvePointX.rawValue].flatMap({ Data(base64Encoded: $0) })
                    else {
                        throw ApolloError.missingKeyParameters(missing: [
                            KeyProperties.rawKey.rawValue, KeyProperties.curvePointX.rawValue
                        ])                    }
                    return Ed25519PublicKey(identifier: identifier, raw: keyData)
                }
                return Ed25519PublicKey(identifier: identifier, raw: keyData)
            case .x25519:
                guard
                    let keyData = parameters[KeyProperties.rawKey.rawValue].flatMap({ Data(base64Encoded: $0) })
                else {
                    guard
                        let keyData = parameters[KeyProperties.curvePointX.rawValue].flatMap({ Data(base64Encoded: $0) })
                    else {
                        throw ApolloError.missingKeyParameters(missing: [
                            KeyProperties.rawKey.rawValue, KeyProperties.curvePointX.rawValue
                        ])
                    }
                    return X25519PublicKey(identifier: identifier, raw: keyData)                }
                return X25519PublicKey(identifier: identifier, raw: keyData)
            }
        default:
            throw ApolloError.invalidKeyType(invalid: keyType, valid: ValidCryptographicTypes.allCases.map(\.rawValue))
        }
    }

    public func createNewLinkSecret() throws -> Key {
        try LinkSecret()
    }
}
