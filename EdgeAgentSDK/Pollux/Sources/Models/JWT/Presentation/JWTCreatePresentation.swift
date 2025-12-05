import Core
import Domain
import Foundation
import JSONWebAlgorithms
import JSONWebKey
import JSONWebSignature
import JSONWebToken
import Sextant

struct JWTCreatePresentation {
    func createPresentation(
        credential: JWTCredential,
        type: String,
        requestData: Data,
        options: [CredentialOperationsOptions]
    ) throws -> String {
        guard
            let subjectDIDOption = options.first(where: {
                if case .subjectDID = $0 { return true }
                return false
            }),
            case let CredentialOperationsOptions.subjectDID(did) = subjectDIDOption
        else {
            throw PolluxError.invalidPrismDID
        }

        guard
            let exportableKeysOption = options.first(where: {
                if case .exportableKeys = $0 { return true }
                return false
            }),
            case let CredentialOperationsOptions.exportableKeys(exportableKeys) = exportableKeysOption,
            let exportableFirstKey = exportableKeys
                .filter({
                    $0.jwk.crv?.lowercased() == "secp256k1"
                    && !($0.jwk.kid?.contains("#master") ?? true) // TODO: This is a hardcoded fix, since prism DID doesnt not recognize master key
            }).first
        else {
            throw PolluxError.requiresExportableKeyForOperation(operation: "Create Presentation JWT Credential")
        }

        switch type {
        case "dif/presentation-exchange/definitions@v1.0":
            return try presentation(
                credential: credential,
                request: requestData,
                did: did,
                exportableKey: exportableFirstKey
            )
        default:
            let payload = try vcPresentation(
                credential: credential,
                request: requestData,
                did: did
            )

            return try vcPresentationJWTString(
                payload: payload,
                exportableKey: exportableFirstKey
            )
        }
    }

    private func presentation(
        credential: JWTCredential,
        request: Data,
        did: DID,
        exportableKey: ExportableKey
    ) throws -> String {
        let presentationRequest = try JSONDecoder.didComm().decode(PresentationExchangeRequest.self, from: request)

        guard
            let jwtFormat = presentationRequest.presentationDefinition.format?.jwt,
            try jwtFormat.supportedTypes.contains(where: { try $0 == credential.getAlg() })
        else {
            throw PolluxError.credentialIsNotOfPresentationDefinitionRequiredAlgorithm
        }

        let credentialSubject = try JSONEncoder().encode(credential.defaultEnvelop)

        try presentationRequest.presentationDefinition.inputDescriptors.forEach {
            try $0.constraints.fields.forEach {
                guard credentialSubject.query(values: $0.path) != nil else {
                    throw PolluxError.credentialDoesntProvideOneOrMoreInputDescriptors(path: $0.path)
                }
            }
        }
        let presentationDefinitions = presentationRequest.presentationDefinition.inputDescriptors.map {
            PresentationSubmission.Descriptor(
                id: $0.id,
                path: "$.verifiable_credential[0]",
                format: "jwt",
                pathNested: .init(
                    id: $0.id,
                    path: "$.vp.verifiableCredential[0].id",
                    format: "jwt"
                )
            )
        }

        let presentationSubmission = PresentationSubmission(
            definitionId: presentationRequest.presentationDefinition.id,
            descriptorMap: presentationDefinitions
        )

        let payload = try vcPresentation(
            credential: credential,
            request: request,
            did: did
        )

        let jwtString = try vcPresentationJWTString(
            payload: payload,
            exportableKey: exportableKey
        )

        let container = PresentationContainer(
            presentationSubmission: presentationSubmission,
            verifiableCredential: [AnyCodable(stringLiteral: jwtString)]
        )

        return try JSONEncoder.didComm().encode(container).tryToString()
    }

    private func vcPresentation(
        credential: JWTCredential,
        request: Data,
        did: DID
    ) throws -> JWTEnvelopedVerifiablePresentation<VerifiablePresentation<OneOrMany<EnvelopedVerfiablePresentation>>> {
        let jsonObject = try JSONSerialization.jsonObject(with: request)
        guard
            let domain = findValue(forKey: "domain", in: jsonObject),
            let challenge = findValue(forKey: "challenge", in: jsonObject)
        else { throw PolluxError.offerDoesntProvideEnoughInformation }

        return JWTEnvelopedVerifiablePresentation(
            iss: did.string,
            aud: [domain],
            nonce: challenge,
            vp: VerifiablePresentation(
                context: .one(W3CRegisteredConstants.verifiableCredential2_0Context),
                type: .one(W3CRegisteredConstants.verifiablePresentationType),
                verifiableCredential: .many([EnvelopedVerfiablePresentation(
                    context: .one(W3CRegisteredConstants.verifiableCredential2_0Context),
                    id: "data:application/vc+jwt,\(credential.jwtString)",
                    type: .one(W3CRegisteredConstants.envelopedVerifiableCredentialType)
                )])
            )
        )
    }

    private func vcPresentationJWTString<Payload: Codable>(
        payload: Payload,
        exportableKey: ExportableKey
    ) throws -> String {
        let keyJWK = exportableKey.jwk

        ES256KSigner.invertedBytesR_S = true

        let jwt = try JWT.signed(
            payload: payload,
            protectedHeader: DefaultJWSHeaderImpl(
                algorithm: .ES256K,
                keyID: keyJWK.kid
            ),
            key: JSONWebKey.JWK(
                keyType: .init(rawValue: keyJWK.kty)!,
                keyID: keyJWK.kid,
                x: keyJWK.x.flatMap { Data(fromBase64URL: $0) },
                y: keyJWK.y.flatMap { Data(fromBase64URL: $0) },
                d: keyJWK.d.flatMap { Data(fromBase64URL: $0) }
            )
        )

        ES256KSigner.invertedBytesR_S = false

        return jwt.jwtString
    }
}

extension JWTCredential {
    func getJSON() throws -> Data {
        return try JWT.getPayload(jwtString: jwtString)
    }

    func getAlg() throws -> String {
        let jwtParts = jwtString.components(separatedBy: ".")
        guard
            let headerString = jwtParts.first,
            let base64Data = Data(fromBase64URL: headerString),
            let alg = try JSONDecoder.didComm().decode(DefaultJWSHeaderImpl.self, from: base64Data).algorithm?.rawValue
        else { throw PolluxError.couldNotFindCredentialAlgorithm }

        return alg
    }
}
