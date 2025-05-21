import Foundation
import TestFramework

/// Initializes CucumberLite configuration
class Config: TestConfiguration {
    static var mediatorOobUrl: String = ""
    static var agentUrl: String = ""
    
    static var publishedSecp256k1Did: String = ""
    static var publishedEd25519Did: String = ""
    
    static var jwtSchemaGuid: String = ""
    static var sdJwtSchemaGuid: String = ""
    static var anoncredDefinitionGuid: String = ""
    
    static var apiKey: String = ""
    
    lazy var api: CloudAgentAPI = {
        return api
    }()
    
    override class func createInstance() -> TestConfiguration {
        return Config(bundlePath: Bundle.module.bundlePath)
    }
    
    override func targetDirectory() -> URL {
        return URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Target")
    }
    
    override func createReporters() async throws -> [Reporter] {
        return [ConsoleReporter(), HtmlReporter(), JunitReporter(), AllureReporter()]
    }
    
    override func createActors() async throws -> [Actor]  {
        let cloudAgent = Actor("Cloud Agent").whoCanUse(CloudAgentAPI())
        let edgeAgent = Actor("Edge Agent").whoCanUse(DidcommAgentAbility())
        let verifierEdgeAgent = Actor("Verifier Edge Agent").whoCanUse(DidcommAgentAbility())
        return [cloudAgent, edgeAgent, verifierEdgeAgent]
    }
    
    override func setUp() async throws {
        Config.mediatorOobUrl = environment["MEDIATOR_OOB_URL"] ?? ""
        Config.agentUrl = environment["PRISM_AGENT_URL"] ?? ""
        Config.publishedSecp256k1Did = environment["PUBLISHED_SECP256K1_DID"] ?? ""
        Config.publishedEd25519Did = environment["PUBLISHED_ED25519_DID"] ?? ""
        Config.jwtSchemaGuid = environment["JWT_SCHEMA_GUID"] ?? ""
        Config.sdJwtSchemaGuid = environment["SDJWT_SCHEMA_GUID"] ?? ""
        Config.anoncredDefinitionGuid = environment["ANONCRED_DEFINITION_GUID"] ?? ""
        Config.apiKey = environment["APIKEY"] ?? ""
        
        let isDebug = ProcessInfo.processInfo.environment["DEBUG"]
        if (isDebug != nil) {
            print("=================== PARAMETERS ===================")
            print("MEDIATOR_OOB_URL", Config.mediatorOobUrl)
            print("PRISM_AGENT_URL", Config.agentUrl)
            print("PUBLISHED_SECP256K1_DID", Config.publishedSecp256k1Did)
            print("PUBLISHED_ED25519_DID", Config.publishedEd25519Did)
            print("JWT_SCHEMA_GUID", Config.jwtSchemaGuid)
            print("SDJWT_SCHEMA_GUID", Config.sdJwtSchemaGuid)
            print("ANONCRED_DEFINITION_GUID", Config.anoncredDefinitionGuid)
            print("APIKEY", Config.apiKey)
            fflush(stdout)
        }
        
        // should be initialized after the configuration variables
        let openEnterpriseApi = CloudAgentAPI()
        try openEnterpriseApi.createClient()
        self.api = openEnterpriseApi
        
        let secp256k1DidExists = try await checkPublishedDid(did: Config.publishedSecp256k1Did)
        if (!secp256k1DidExists) {
            print("Secp256k1 DID not found.")
            let shortFormDid = try await createPublishedDid(curve: .secp256k1)
            Config.publishedSecp256k1Did = shortFormDid
        }
        
        let ed25519DidExists = try await checkPublishedDid(did: Config.publishedEd25519Did)
        if (!ed25519DidExists) {
            print("Ed25519 DID not found.")
            let shortFormDid = try await createPublishedDid(curve: .Ed25519)
            Config.publishedEd25519Did = shortFormDid
        }
        
        let jwtSchemaExists = try await checkSchema(guid: Config.jwtSchemaGuid)
        if (!jwtSchemaExists) {
            print("JWT Schema not found.")
            let guid = try await createSchema(did: Config.publishedSecp256k1Did)
            Config.jwtSchemaGuid = guid
        }
        
        let sdJwtSchemaExists = try await checkSchema(guid: Config.sdJwtSchemaGuid)
        if (!sdJwtSchemaExists) {
            print("SD+JWT Schema not found.")
            let guid = try await createSchema(did: Config.publishedEd25519Did)
            Config.sdJwtSchemaGuid = guid
        }
        
        try await checkAnoncredDefinition()
        
        print("Mediator", Config.mediatorOobUrl)
        print("Agent", Config.agentUrl)
        print("secp256k1 did", Config.publishedSecp256k1Did)
        print("Ed25519 did", Config.publishedEd25519Did)
        print("JWT Schema", Config.jwtSchemaGuid)
        print("SD+JWT Schema", Config.sdJwtSchemaGuid)
        print("Anoncred Definition", Config.anoncredDefinitionGuid)
    }
    
    override func tearDown() async throws {
    }
    
    private func checkPublishedDid(did: String) async throws -> Bool {
        return try await api.isDidPresent(did)
    }
    
    private func createPublishedDid(curve: Components.Schemas.Curve) async throws -> String {
        let unpublishedDid = try await api.createUnpublishedDid(curve: curve)
        let publishedDid = try await api.publishDid(unpublishedDid.longFormDid)
        let shortFormDid = publishedDid.scheduledOperation.didRef
        
        try await Wait.until(timeout: 60) {
            let did = try await api.getDid(shortFormDid)
            return did.status == "PUBLISHED"
        }
        
        return shortFormDid
    }
    
    private func checkSchema(guid: String) async throws -> Bool {
        return try await api.isSchemaGuidPresent(guid)
    }
    
    private func createSchema(did: String) async throws -> String {
        let schema = try await api.createSchema(did: did)
        return schema.guid
    }
    
    private func checkAnoncredDefinition() async throws {
        let isPresent = try await api.isAnoncredDefinitionPresent(Config.anoncredDefinitionGuid)
        if (isPresent) {
            return
        }
        print("Anoncred Definition not found for [\(Config.anoncredDefinitionGuid)]. Creating a new one.")
        
        let anoncredSchema = try await api.createAnoncredSchema(Config.publishedSecp256k1Did)
        let anoncredDefinition = try await api.createAnoncredDefinition(Config.publishedSecp256k1Did, anoncredSchema.guid)
        Config.anoncredDefinitionGuid = anoncredDefinition.guid
    }
    
    private func writeToGithubSummary(_ command: String) {
        //        if (ProcessInfo.processInfo.environment.keys.contains("CI")) {
        let process = Process()
        process.launchPath = "/bin/bash"
        process.arguments = ["-c", command]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            print("Command output:\n\(output)")
        }
    }
}

class ConfigError {
    final class publishedDIDNotFound: BaseError {
        init(file: StaticString = #file, line: UInt = #line) {
            super.init(message: "Error while getting published DID", error: "Configuration error", file: file, line: line)
        }
    }
}
