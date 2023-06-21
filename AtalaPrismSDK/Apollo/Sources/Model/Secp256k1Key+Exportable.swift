import Domain
import Foundation

extension Secp256k1PrivateKey: ExportableKey {
    var pem: String {
        PEMKey(
            keyType: "EC PRIVATE KEY",
            keyData: raw
        ).pemEncoded()
    }

    var jwk: JWK {
        JWK(
            kty: "OKP",
            d: raw.base64UrlEncodedString(),
            crv: getProperty(.curve)?.capitalized,
            x: publicKey().getProperty(.curvePointX).flatMap { Data(fromBase64URL: $0)?.base64UrlEncodedString() },
            y: publicKey().getProperty(.curvePointY).flatMap { Data(fromBase64URL: $0)?.base64UrlEncodedString() }
        )
    }

    func jwkWithKid(kid: String) -> JWK {
        JWK(
            kty: "OKP",
            kid: kid,
            d: raw.base64UrlEncodedString(),
            crv: getProperty(.curve)?.capitalized,
            x: publicKey().getProperty(.curvePointX).flatMap { Data(fromBase64URL: $0)?.base64UrlEncodedString() },
            y: publicKey().getProperty(.curvePointY).flatMap { Data(fromBase64URL: $0)?.base64UrlEncodedString() }
        )
    }
}

extension Secp256k1PublicKey: ExportableKey {
    var pem: String {
        PEMKey(
            keyType: "EC PUBLIC KEY",
            keyData: raw
        ).pemEncoded()
    }

    var jwk: JWK {
        JWK(
            kty: "OKP",
            crv: getProperty(.curve)?.capitalized,
            x: getProperty(.curvePointX)
                .flatMap { Data(fromBase64URL: $0)?.base64UrlEncodedString() } ?? raw.base64UrlEncodedString(),
            y: getProperty(.curvePointY).flatMap { Data(fromBase64URL: $0)?.base64UrlEncodedString() }
        )
    }

    func jwkWithKid(kid: String) -> JWK {
        JWK(
            kty: "OKP",
            kid: kid,
            crv: getProperty(.curve)?.capitalized,
            x: getProperty(.curvePointX)
                .flatMap { Data(fromBase64URL: $0)?.base64UrlEncodedString() } ?? raw.base64UrlEncodedString(),
            y: getProperty(.curvePointY).flatMap { Data(fromBase64URL: $0)?.base64UrlEncodedString() }
        )
    }
}
