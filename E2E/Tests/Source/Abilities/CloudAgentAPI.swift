import Foundation
import OpenAPIRuntime
import OpenAPIURLSession
import HTTPTypes
import TestFramework

class CloudAgentAPI: Ability {
    let uuid = UUID().uuidString
    lazy var actor: Actor = {
        return actor
    }()
    let abilityName: String = "identus cloud-agent api"

    private var initialized: Bool = false
    
    private lazy var transport: URLSessionTransport = { return transport }()
    private lazy var client: Client = { return client }()
    
    required init() {}
    
    func isInitialized() -> Bool {
        return initialized
    }

    func initialize() async throws {
        self.actor = actor
        try createClient(StepReporterMiddleware(actor.name))
        self.initialized = true
    }
    
    func setActor(_ actor: Actor) {
        self.actor = actor
    }
    
    func createClient(_ middlewares: ClientMiddleware...) throws {
        transport = URLSessionTransport()
        client = Client(
            serverURL: URL(string: Config.agentUrl)!,
            configuration: .init(dateTranscoder: MyDateTranscoder()),
            transport: transport,
            middlewares: [APITokenMiddleware(apikey: Config.apiKey)] + middlewares
        )
    }
    
    func tearDown() async throws {
    }
    
    func isDidPresent(_ did: String) async throws -> Bool {
        if (did.isEmpty) {
            return false
        }
        
        do {
            let did = try await getDid(did)
            return did.status == "PUBLISHED"
        } catch {
            return false
        }
    }
    
    func getDid(_ did: String) async throws -> Components.Schemas.ManagedDID {
        let response = try await client.getDid_hyphen_registrarDidsDidref(.init(path: .init(didRef: did)))
        switch(response) {
        case .ok(let okResponse):
            switch(okResponse.body) {
            case .json(let body):
                return body
            }
        default:
            throw Error.WrongResponse(response)
        }
    }
    
    func createUnpublishedDid(curve: Components.Schemas.Curve) async throws -> Components.Schemas.CreateManagedDIDResponse {
        let createManagedDidRequest = Components.Schemas.CreateManagedDidRequest(
            documentTemplate: .init(
                publicKeys: .init(
                    arrayLiteral: .init(
                        id: "assertion-key",
                        purpose: .assertionMethod,
                        curve: curve
                    ),
                    .init(
                        id: "authentication-key",
                        purpose: .authentication,
                        curve: curve
                    )
                ),
                services: []
            )
        )
        
        let response = try await client.postDid_hyphen_registrarDids(body: .json(createManagedDidRequest))
        
        switch(response) {
        case .created(let createdResponse):
            switch(createdResponse.body) {
            case .json(let body):
                return body
            }
        default:
            throw Error.WrongResponse(response)
        }
    }
    
    func publishDid(_ longFormDid: String) async throws -> Components.Schemas.DIDOperationResponse {
        let response = try await client.postDid_hyphen_registrarDidsDidrefPublications(path: .init(didRef: longFormDid))
        switch (response) {
        case .accepted(let acceptedResponse):
            switch(acceptedResponse.body) {
            case .json(let body):
                return body
            }
        default:
            throw Error.WrongResponse(response)
        }
    }
    
    func isSchemaGuidPresent(_ guid: String) async throws -> Bool {
        if (guid.isEmpty) {
            return false
        }
        
        do {
            _ = try await getJwtSchema(guid)
            return true
        } catch {
            return false
        }
    }
    
    func getJwtSchema(_ guid: String) async throws -> Components.Schemas.CredentialSchemaResponse {
        let response = try await client.getSchemaById(path: .init(guid: guid))
        
        switch(response) {
        case .ok(let okResponse):
            switch(okResponse.body) {
            case .json(let body):
                return body
            }
        default:
            throw Error.WrongResponse(response)
        }
    }
    
    func createSchema(did: String) async throws -> Components.Schemas.CredentialSchemaResponse {
        let schemaName = "automation-jwt-schema-" + UUID().uuidString
        var schema = try OpenAPIValueContainer()
        schema.value = [
            "$id": "https://example.com/\(schemaName)",
            "$schema": "https://json-schema.org/draft/2020-12/schema",
            "description": "Automation schema description",
            "type": "object",
            "properties": [
                "automation-required": [
                    "type": "string"
                ],
                "automation-optional": [
                    "type": "string"
                ]
            ]
        ]
        
        let credentialSchemaInput = Components.Schemas.CredentialSchemaInput(
            name: schemaName,
            version: "0.0.1",
            description: "Some description to automation generated schema",
            _type: "https://w3c-ccg.github.io/vc-json-schemas/schema/2.0/schema.json",
            schema: schema,
            tags: ["automation"],
            author: did
        )
        
        let response = try await client.createSchema(body: .json(credentialSchemaInput))
        switch (response) {
        case .created(let createdResponse):
            switch (createdResponse.body) {
            case .json(let body):
                return body
            }
        default:
            throw Error.WrongResponse(response)
        }
    }

    func isAnoncredDefinitionPresent(_ anoncredDefinitionGuid: String) async throws -> Bool {
        if (anoncredDefinitionGuid.isEmpty) {
            return false
        }
        
        do {
            _ = try await getAnoncredDefinition(anoncredDefinitionGuid)
            return true
        } catch {
            return false
        }
    }
    
    func getAnoncredDefinition(_ anoncredDefinitionGuid: String) async throws -> Components.Schemas.CredentialDefinitionResponse {
        let response = try await client.getCredentialDefinitionByIdHttpUrl(path: .init(guid: anoncredDefinitionGuid))
        
        switch(response) {
        case .ok(let okResponse):
            switch(okResponse.body){
            case .json(let body):
                return body
            }
        default:
            throw Error.WrongResponse(response)
        }
    }
    
    func createAnoncredSchema(_ issuerId: String) async throws -> Components.Schemas.CredentialSchemaResponse {
        let schemaName = "automation-anoncred-schema-" + UUID().uuidString
        
        var schema = try OpenAPIValueContainer()
        schema.value = [
            "name": "Automation Anoncred",
            "version": "1.0",
            "issuerId": issuerId,
            "attrNames": [
                "name",
                "age",
                "gender"
            ]
        ]
        
        let credentialSchemaInput = Components.Schemas.CredentialSchemaInput(
            name: schemaName,
            version: "2.0.0",
            description: "Some description to automation generated schema",
            _type: "AnoncredSchemaV1",
            schema: schema,
            tags: ["automation"],
            author: issuerId
        )
        
        let response = try await client.createSchema(body: .json(credentialSchemaInput))
        switch (response) {
        case .created(let createdResponse):
            switch (createdResponse.body) {
            case .json(let body):
                return body
            }
        default:
            throw Error.WrongResponse(response)
        }
    }
    
    func createAnoncredDefinition(_ issuerId: String, _ anoncredSchemaGuid: String) async throws -> Components.Schemas.CredentialDefinitionResponse {
        let definitionName = "automation-anoncred-definition-" + UUID().uuidString
        let anoncredDefinition = Components.Schemas.CredentialDefinitionInput.init(
            name: definitionName,
            description: "Test Automation Auto-Generated",
            version: "1.0.0",
            tag: "automation-test",
            author: issuerId,
            schemaId: "\(Config.agentUrl)/schema-registry/schemas/\(anoncredSchemaGuid)/schema",
            signatureType: "CL",
            supportRevocation: false
        )
        
        let response = try await client.createCredentialDefinitionHttpUrl(body: .json(anoncredDefinition))
        switch(response) {
        case .created(let createdResponse):
            switch(createdResponse.body) {
            case .json(let body):
                return body
            }
        default:
            throw Error.WrongResponse(response)
        }
    }
    
    func getConnections() async throws -> Components.Schemas.ConnectionsPage {
        let response = try await client.getConnections(.init())
        
        switch(response) {
        case .ok(let okResponse):
            switch(okResponse.body) {
            case .json(let response):
                return response
            }
        default:
            throw Error.WrongResponse(response)
        }
    }
    
    func getConnection(_ connectionId: String) async throws -> Components.Schemas.Connection {
        let response = try await client.getConnection(path: .init(connectionId: connectionId))
        
        switch(response) {
        case .ok(let okResponse):
            switch(okResponse.body) {
            case .json(let response):
                return response
            }
        default:
            throw Error.WrongResponse(response)
        }
    }
    
    func createConnection(label: String?, goalCode: String?, goal: String?) async throws -> Components.Schemas.Connection {
        let body = Components.Schemas.CreateConnectionRequest(
            label: label,
            goalCode: goalCode,
            goal: goal
        )
    
        let response = try await client.createConnection(.init(body: .json(body)))
        
        switch(response) {
        case .created(let okResponse):
            switch(okResponse.body) {
            case .json(let body):
                return body
            }
        default:
            throw Error.WrongResponse(response)
        }
    }
    
    func offerCredential(_ connectionId: String) async throws -> Components.Schemas.IssueCredentialRecord {
        var claims: OpenAPIValueContainer = try OpenAPIValueContainer()
        claims.value = [
            "automation-required" : UUID().uuidString
        ]
        
        let body = Components.Schemas.CreateIssueCredentialRecordRequest(
            schemaId: .case2("\(Config.agentUrl)/schema-registry/schemas/\(Config.jwtSchemaGuid)"),
            claims: claims,
            issuingDID: Config.publishedSecp256k1Did,
            connectionId: connectionId
        )
        
        let response = try await client.createCredentialOffer(body: .json(body))
        switch(response) {
        case .created(let createdResponse):
            switch(createdResponse.body){
            case .json(let body):
                return body
            }
        default:
            throw Error.WrongResponse(response)
        }
    }
    
    func offerAnonymousCredential(_ connectionId: String) async throws -> Components.Schemas.IssueCredentialRecord {
        var claims: OpenAPIValueContainer = try OpenAPIValueContainer()
        claims.value = [
            "name" : "automation",
            "age" : "99",
            "gender": "M"
        ]
        
        let body = Components.Schemas.CreateIssueCredentialRecordRequest(
            credentialDefinitionId: Config.anoncredDefinitionGuid,
            credentialFormat: "AnonCreds",
            claims: claims,
            automaticIssuance: true,
            issuingDID: Config.publishedSecp256k1Did,
            connectionId: connectionId
        )
        
        let response = try await client.createCredentialOffer(body: .json(body))
        switch(response) {
        case .created(let createdResponse):
            switch(createdResponse.body){
            case .json(let body):
                return body
            }
        default:
            throw Error.WrongResponse(response)
        }
    }
    
    func offerSdJwtCredential(_ connectionId: String) async throws -> Components.Schemas.IssueCredentialRecord {
        var claims: OpenAPIValueContainer = try OpenAPIValueContainer()
        claims.value = [
            "automation-required" : "automation"
        ]
        
        let body = Components.Schemas.CreateIssueCredentialRecordRequest(
            validityPeriod: 360000,
            schemaId: .case2("\(Config.agentUrl)/schema-registry/schemas/\(Config.sdJwtSchemaGuid)"),
            credentialFormat: "SDJWT",
            claims: claims,
            automaticIssuance: true,
            issuingDID: Config.publishedEd25519Did,
            connectionId: connectionId,
            goalCode: "77",
            goal: "automation goal"
        )
        
        let response = try await client.createCredentialOffer(body: .json(body))
        switch(response) {
        case .created(let createdResponse):
            switch(createdResponse.body){
            case .json(let body):
                return body
            }
        default:
            throw Error.WrongResponse(response)
        }
    }
    
    func getCredentialRecord(_ recordId: String) async throws -> Components.Schemas.IssueCredentialRecord {
        let response = try await client.getCredentialRecord(path: .init(recordId: recordId))
        switch(response){
        case .ok(let okResponse):
            switch(okResponse.body){
            case .json(let body):
                return body
            }
        default:
            throw Error.WrongResponse(response)
        }
    }
    
    func requestPresentProof(_ connectionId: String) async throws -> Components.Schemas.PresentationStatus {
        let options = Components.Schemas.Options(
            challenge: UUID().uuidString,
            domain: Config.agentUrl
        )
        
        let proof = Components.Schemas.ProofRequestAux(
            schemaId: "\(Config.agentUrl)/schema-registry/schemas/\(Config.jwtSchemaGuid)",
            trustIssuers: [Config.publishedSecp256k1Did]
        )
        
        let body = Components.Schemas.RequestPresentationInput(
            connectionId: connectionId,
            options: options,
            proofs: [proof],
            credentialFormat: "JWT"
        )
        
        let response = try await client.requestPresentation(body: .json(body))
        
        switch(response){
        case .created(let createdResponse):
            switch(createdResponse.body){
            case .json(let body):
                return body
            }
        default:
            throw Error.WrongResponse(response)
        }
    }
    
    func requestSdJwtPresentProof(_ connectionId: String) async throws -> Components.Schemas.PresentationStatus {
        let options = Components.Schemas.Options(
            challenge: UUID().uuidString,
            domain: Config.agentUrl
        )
        let proof = Components.Schemas.ProofRequestAux(
            schemaId: "\(Config.agentUrl)/schema-registry/schemas/\(Config.sdJwtSchemaGuid)",
            trustIssuers: [Config.publishedEd25519Did]
        )
        let claims = Components.Schemas.Obj()
        
        let presentProofRequest = Components.Schemas.RequestPresentationInput(
            connectionId: connectionId,
            options: options,
            proofs: [proof],
            claims: claims,
            credentialFormat: "SDJWT"
        )

        let response = try await client.requestPresentation(body: .json(presentProofRequest))
        
        switch(response){
        case .created(let createdResponse):
            switch(createdResponse.body){
            case .json(let body):
                return body
            }
        default:
            throw Error.WrongResponse(response)
        }
    }
    
    func requestAnonymousPresentProof(_ connectionId: String) async throws -> Components.Schemas.PresentationStatus {
        let credentialDefinitionUrl = Config.agentUrl + "/credential-definition-registry/definitions/" + Config.anoncredDefinitionGuid + "/definition"
        let anoncredPresentationRequest = Components.Schemas.AnoncredPresentationRequestV1(
            requested_attributes: .init(additionalProperties: [
                "gender": .init(
                    name: "gender",
                    restrictions: [
                        .init(additionalProperties: [
                            "attr::gender::value": "M",
                            "cred_def_id": credentialDefinitionUrl
                        ])
                    ]
                )
            ]),
            requested_predicates: .init(additionalProperties: [
                "age": .init(
                    name: "age",
                    p_type: ">",
                    p_value: 18,
                    restrictions: []
                )
            ]),
            name: "proof_req_1",
            nonce: Utils.generateNonce(length: 25),
            version: "1.0"
        )
        
        let body = Components.Schemas.RequestPresentationInput(
            connectionId: connectionId,
            options: nil,
            proofs: [],
            anoncredPresentationRequest: anoncredPresentationRequest,
            credentialFormat: "AnonCreds"
        )
        
        let response = try await client.requestPresentation(body: .json(body))
        
        switch(response){
        case .created(let createdResponse):
            switch(createdResponse.body){
            case .json(let body):
                return body
            }
        default:
            throw Error.WrongResponse(response)
        }
    }
    
    func requestAnonymousPresentProofWithUnexpectedAttributes(_ connectionId: String) async throws -> Components.Schemas.PresentationStatus {
        let credentialDefinitionUrl = Config.agentUrl + "/credential-definition-registry/definitions/" + Config.anoncredDefinitionGuid + "/definition"
        let anoncredPresentationRequest = Components.Schemas.AnoncredPresentationRequestV1(
            requested_attributes: .init(additionalProperties: [
                "driversLicense": .init(
                    name: "driversLicense",
                    restrictions: [
                        .init(additionalProperties: [
                            "attr::driversLicense::value": "B",
                            "cred_def_id": credentialDefinitionUrl
                        ])
                    ]
                )
            ]),
            requested_predicates: .init(additionalProperties: [:]),
            name: "proof_req_1",
            nonce: Utils.generateNonce(length: 25),
            version: "1.0"
        )
        
        let body = Components.Schemas.RequestPresentationInput(
            connectionId: connectionId,
            options: nil,
            proofs: [],
            anoncredPresentationRequest: anoncredPresentationRequest,
            credentialFormat: "AnonCreds"
        )
        
        let response = try await client.requestPresentation(body: .json(body))
        
        switch(response){
        case .created(let createdResponse):
            switch(createdResponse.body){
            case .json(let body):
                return body
            }
        default:
            throw Error.WrongResponse(response)
        }
    }
    
    func getPresentation(_ presentationId: String) async throws -> Components.Schemas.PresentationStatus {
        let response = try await client.getPresentation(path: .init(presentationId: presentationId))
        switch(response){
        case .ok(let okResponse):
            switch(okResponse.body){
            case .json(let body):
                return body
            }
        default:
            throw Error.WrongResponse(response)
        }
    }
    
    func revokeCredential(_ recordId: String) async throws -> Int {
        let response = try await client.patchCredential_hyphen_statusRevoke_hyphen_credentialId(path: .init(id: recordId))
        switch(response) {
        case .ok(_):
            return 200
        default:
            throw Error.WrongResponse(response)
        }
    }
    
    enum Error: Swift.Error {
        case WrongResponse(_ response: Any)
    }
    
}

// https://github.com/apple/swift-openapi-generator/issues/84
struct MyDateTranscoder: DateTranscoder {
    private var dateFormatters: [DateFormatter] = []
    
    func encode(_ date: Date) throws -> String {
        return dateFormatters[0].string(from: date)
    }
    
    func decode(_ string: String) throws -> Date {
        for formatter in dateFormatters {
            if let result = formatter.date(from: string) {
                return result
            }
        }
        throw DecodingError.dataCorrupted(.init(
            codingPath: [],
            debugDescription: "Date string does not match any of the expected formats"))
    }
    
    init() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSS'Z'"
        dateFormatters.append(dateFormatter)
    }
}

extension HTTPField.Name {
    static let apikey = Self("apikey")!
}

struct APITokenMiddleware: ClientMiddleware {
    let apikey: String
    
    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var request = request
        request.headerFields[.apikey] = apikey
        return try await next(request, body, baseURL)
    }
    
    init(apikey: String) {
        self.apikey = apikey
    }
}

struct StepReporterMiddleware: ClientMiddleware {
    private var actor: String
    
    init(_ actor: String) {
        self.actor = actor
    }
    
    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        return try await next(request, body, baseURL)
    }
}
