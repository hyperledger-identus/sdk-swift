import Foundation
import OpenAPIRuntime
import OpenAPIURLSession
import HTTPTypes

class OpenEnterpriseAPI: Ability {
    typealias AbilityInstanceType = API
    private var api: AbilityInstanceType? = nil
    
    let actor: Actor
    let abilityName: String = "OEA API"
    
    required init(_ actor: Actor) {
        self.actor = actor
    }
    
    func instance() -> AbilityInstanceType {
        return api!
    }
    
    func setUp(_ actor: Actor) async throws {
        api = API(StepReporterMiddleware(actor.name))
    }
    
    func tearDown() async throws {
    }
    
    class API {
        private var transport: URLSessionTransport? = nil
        private var client: Client? = nil
        
        init(_ middlewares: ClientMiddleware...) {
            transport = URLSessionTransport()
            client = Client(
                serverURL: URL(string: Config.agentUrl)!,
                configuration: .init(dateTranscoder: MyDateTranscoder()),
                transport: transport!,
                middlewares: [APITokenMiddleware(apikey: Config.apiKey)] + middlewares
            )
        }
        
        func isDidPresent(_ did: String) async throws -> Bool {
            if (did.isEmpty) {
                return false
            }
            
            do {
                _ = try await getDid(did)
                return true
            } catch {
                return false
            }
        }
        
        func getDid(_ did: String) async throws -> Components.Schemas.ManagedDID {
            let response = try await client!.getDid_hyphen_registrarDidsDidref(.init(path: .init(didRef: did)))
            switch(response) {
            case .ok(let okResponse):
                switch(okResponse.body) {
                case .json(let body):
                    return body
                }
            default:
                throw Error.WrongResponse
            }
        }
        
        func createUnpublishedDid() async throws -> Components.Schemas.CreateManagedDIDResponse {
            let createManagedDidRequest = Components.Schemas.CreateManagedDidRequest(
                documentTemplate: .init(
                    publicKeys: .init(
                        arrayLiteral: .init(
                            id: "key-1",
                            purpose: .assertionMethod
                        )
                    ),
                    services: []
                )
            )
            
            let response = try await client!.postDid_hyphen_registrarDids(body: .json(createManagedDidRequest))
            
            switch(response) {
            case .created(let createdResponse):
                switch(createdResponse.body) {
                case .json(let body):
                    return body
                }
            default:
                throw Error.WrongResponse
            }
        }
        
        func publishDid(_ longFormDid: String) async throws -> Components.Schemas.DIDOperationResponse {
            let response = try await client!.postDid_hyphen_registrarDidsDidrefPublications(path: .init(didRef: longFormDid))
            switch (response) {
            case .accepted(let acceptedResponse):
                switch(acceptedResponse.body) {
                case .json(let body):
                    return body
                }
            default:
                throw Error.WrongResponse
            }
        }
        
        func isJwtSchemaGuidPresent(_ guid: String) async throws -> Bool {
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
            let response = try await client!.getSchemaById(path: .init(guid: guid))
            
            switch(response) {
            case .ok(let okResponse):
                switch(okResponse.body) {
                case .json(let body):
                    return body
                }
            default:
                throw Error.WrongResponse
            }
        }
        
        func createJwtSchema(author: String) async throws -> Components.Schemas.CredentialSchemaResponse {
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
                author: author
            )
            
            let response = try await client!.createSchema(body: .json(credentialSchemaInput))
            switch (response) {
            case .created(let createdResponse):
                switch (createdResponse.body) {
                case .json(let body):
                    return body
                }
            default:
                throw Error.WrongResponse
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
            let response = try await client!.getCredentialDefinitionById(path: .init(guid: anoncredDefinitionGuid))
            
            switch(response) {
            case .ok(let okResponse):
                switch(okResponse.body){
                case .json(let body):
                    return body
                }
            default:
                throw Error.WrongResponse
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
                    "age"
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
            
            let response = try await client!.createSchema(body: .json(credentialSchemaInput))
            switch (response) {
            case .created(let createdResponse):
                switch (createdResponse.body) {
                case .json(let body):
                    return body
                }
            default:
                throw Error.WrongResponse
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
                schemaId: "\(Config.agentUrl)/schema-registry/schemas/\(anoncredSchemaGuid)",
                signatureType: "CL",
                supportRevocation: true
            )
            
            let response = try await client!.createCredentialDefinition(body: .json(anoncredDefinition))
            switch(response) {
            case .created(let createdResponse):
                switch(createdResponse.body) {
                case .json(let body):
                    return body
                }
            default:
                throw Error.WrongResponse
            }
        }
        
        func getConnections() async throws -> Components.Schemas.ConnectionsPage {
            let response = try await client!.getConnections(.init())
            
            switch(response) {
            case .ok(let okResponse):
                switch(okResponse.body) {
                case .json(let response):
                    return response
                }
            default:
                throw Error.WrongResponse
            }
        }
        
        func getConnection(_ connectionId: String) async throws -> Components.Schemas.Connection {
            let response = try await client!.getConnection(path: .init(connectionId: connectionId))
            
            switch(response) {
            case .ok(let okResponse):
                switch(okResponse.body) {
                case .json(let response):
                    return response
                }
            default:
                throw Error.WrongResponse
            }
        }
        
        func createConnection() async throws -> Components.Schemas.Connection {
            let body = Components.Schemas.CreateConnectionRequest(label: "Alice")
            let response = try await client!.createConnection(.init(body: .json(body)))
            
            switch(response) {
            case .created(let okResponse):
                switch(okResponse.body) {
                case .json(let body):
                    return body
                }
            default:
                throw Error.WrongResponse
            }
        }
        
        func offerCredential(_ connectionId: String) async throws -> Components.Schemas.IssueCredentialRecord {
            var claims: OpenAPIValueContainer = try OpenAPIValueContainer()
            claims.value = [
                "automation-required" : UUID().uuidString
            ]
            
            let body = Components.Schemas.CreateIssueCredentialRecordRequest(
                schemaId: "\(Config.agentUrl)/schema-registry/schemas/\(Config.jwtSchemaGuid)",
                claims: claims,
                issuingDID: Config.publishedDid,
                connectionId: connectionId
            )
            
            let response = try await client!.createCredentialOffer(body: .json(body))
            switch(response) {
            case .created(let createdResponse):
                switch(createdResponse.body){
                case .json(let body):
                    return body
                }
            default:
                throw Error.WrongResponse
            }
        }
        
        func offerAnonymousCredential(_ connectionId: String) async throws -> Components.Schemas.IssueCredentialRecord {
            var claims: OpenAPIValueContainer = try OpenAPIValueContainer()
            claims.value = [
                "name" : "automation",
                "age" : "99"
            ]
            
            let body = Components.Schemas.CreateIssueCredentialRecordRequest(
                credentialDefinitionId: Config.anoncredDefinitionGuid,
                credentialFormat: "AnonCreds",
                claims: claims,
                automaticIssuance: true,
                issuingDID: Config.publishedDid,
                connectionId: connectionId
            )
            
            let response = try await client!.createCredentialOffer(body: .json(body))
            switch(response) {
            case .created(let createdResponse):
                switch(createdResponse.body){
                case .json(let body):
                    return body
                }
            default:
                throw Error.WrongResponse
            }
        }
        
        func getCredentialRecord(_ recordId: String) async throws -> Components.Schemas.IssueCredentialRecord {
            let response = try await client!.getCredentialRecord(path: .init(recordId: recordId))
            switch(response){
            case .ok(let okResponse):
                switch(okResponse.body){
                case .json(let body):
                    return body
                }
            default:
                throw Error.WrongResponse
            }
        }
        
        func requestPresentProof(_ connectionId: String) async throws -> Components.Schemas.PresentationStatus {
            let options = Components.Schemas.Options(
                challenge: UUID().uuidString,
                domain: Config.agentUrl
            )
            
            let proof = Components.Schemas.ProofRequestAux(
                schemaId: Config.jwtSchemaGuid,
                trustIssuers: []
            )
            
            let body = Components.Schemas.RequestPresentationInput(
                connectionId: connectionId,
                options: options,
                proofs: [proof],
                credentialFormat: "JWT"
            )
            
            let response = try await client!.requestPresentation(body: .json(body))
            
            switch(response){
            case .created(let createdResponse):
                switch(createdResponse.body){
                case .json(let body):
                    return body
                }
            default:
                throw Error.WrongResponse
            }
        }
        
        func getPresentation(_ presentationId: String) async throws -> Components.Schemas.PresentationStatus {
            let response = try await client!.getPresentation(path: .init(presentationId: presentationId))
            switch(response){
            case .ok(let okResponse):
                switch(okResponse.body){
                case .json(let body):
                    return body
                }
            default:
                throw Error.WrongResponse
            }
        }
        
        enum Error: Swift.Error, Equatable {
            case WrongResponse
        }
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
