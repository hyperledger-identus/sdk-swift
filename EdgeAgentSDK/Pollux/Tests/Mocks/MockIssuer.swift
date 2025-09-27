import AnoncredsSwift
import Domain
import Foundation

struct MockIssuer {

    let issuer = "mock:issuer_id/path&q=bar"
    let linkSecret: LinkSecret
    let schema: Schema
    let credDef: CredentialDefinition
    let credDefPriv: CredentialDefinitionPrivate
    let credDefCorrProof: CredentialKeyCorrectnessProof

    init() {
        self.linkSecret = try! LinkSecret.newFromValue(valueString: "65965334953670062552662719679603258895632947953618378932199361160021795698890")

        self.schema = try! Issuer().createSchema(
            schemaName: "mock:uri2",
            schemaVersion: "0.1.0",
            issuerId: issuer,
            attrNames: ["name", "sex", "age"]
        )

        let credDef = try! Issuer().createCredentialDefinition(
            schemaId: schema.name,
            schema: schema,
            issuerId: issuer,
            tag: "tag",
            signatureType: .cl,
            config: .init(supportRevocation: false)
        )

        self.credDef = credDef.credentialDefinition
        self.credDefPriv = credDef.credentialDefinitionPrivate
        self.credDefCorrProof = credDef.credentialKeyCorrectnessProof
    }
    
    func createCredDefinition() throws {
        let credDef = try! Issuer().createCredentialDefinition(
            schemaId: "http://localhost:8000/schemas/test",
            schema: schema,
            issuerId: issuer,
            tag: "test",
            signatureType: .cl,
            config: .init(supportRevocation: false)
        )
    }
    
    func createOffer() throws -> CredentialOffer {
        try Issuer().createCredentialOffer(
            schemaId: "mock:uri2",
            credDefId: "mock:uri3",
            correctnessProof: credDefCorrProof
        )
    }

    func createOfferMessage() throws -> Message {
        let offer = try createOffer().getJson()

        return Message(
            piuri: "https://didcomm.org/issue-credential/3.0/offer-credential",
            body: Data(),
            attachments: [
                .init(
                    id: "test1",
                    mediaType: nil,
                    data: AttachmentBase64(base64: offer.data(using: .utf8)!.base64EncodedString()),
                    filename: nil,
                    format: "anoncreds/credential-offer@v1.0",
                    lastmodTime: nil,
                    byteCount: nil,
                    description: nil
                )
            ],
            thid: "1"
        )
    }

    func issueCredential(
        offer: CredentialOffer,
        request: CredentialRequest
    ) throws -> Message {
        let issued = try Issuer().createCredential(
            credDef: credDef,
            credDefPrivate: credDefPriv,
            credOffer: offer,
            credRequest: request,
            credValues: [
                .init(raw: "name", encoded: "Miguel"),
                .init(raw: "sex", encoded: "M"),
                .init(raw: "age", encoded: "31")
            ],
            revRegId: nil,
            revStatusList: nil,
            revocationConfig: nil
        ).getJson()

        return Message(
            piuri: "https://didcomm.org/issue-credential/3.0/issue-credential",
            body: Data(),
            attachments: [
                .init(
                    id: "test1",
                    mediaType: nil,
                    data: AttachmentBase64(base64: issued.data(using: .utf8)!.base64EncodedString()),
                    filename: nil,
                    format: "anoncreds/credential@v1.0",
                    lastmodTime: nil,
                    byteCount: nil,
                    description: nil
                )
            ],
            thid: "1"
        )
    }

    func createPresentationRequest() throws -> (request: Data, requestStr: String) {
        let presentation = """
{"nonce":"1103253414365527824079144","name":"proof_req_1","version":"0.1","requested_attributes":{"sex":{"name":"sex", "restrictions":{"attr::sex::value":"M","cred_def_id":"mock:uri3"}}},"requested_predicates":{"age":{"name":"age", "p_type":">=", "p_value":18}}}
"""
        return (try presentation.tryData(using: .utf8), presentation)
    }

    func getSchemaJson() -> String {
"""
{"name":"\(schema.name)","issuerId":"\(schema.issuerId)","version":"\(schema.version)","attrNames":["name", "sex", "age"]}
"""
    }

    func verifyPresentation(presentation: String, request: String) throws -> Bool {
        let presentation = try Presentation(jsonString: presentation)
        let request = try PresentationRequest(jsonString: request)
        let credDef = self.credDef
        let schema = self.schema
        return try Verifier().verifyPresentation(
            presentation: presentation,
            presentationRequest: request,
            schemas: ["mock:uri2": schema],
            credentialDefinitions: ["mock:uri3": credDef]
        )
    }
}
