import Foundation

public class JunitReporter: Reporter {
    let root = XMLElement(name: "testsuites")
    let xml: XMLDocument
    
    var currentFeature = XMLElement(name: "testsuite")
    var currentScenario = XMLElement(name: "testcase")
    
    let testSuitesStart = Date()
    var featureStart = Date()
    var scenarioStart = Date()
    
    var totalTests: Int = 0
    var totalFailures: Int = 0
    var featureTests: Int = 0
    var featureFailures: Int = 0

    required public init() {
        xml = XMLDocument(rootElement: root)
        xml.version = "1.0"
        xml.characterEncoding = "UTF-8"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"

        let currentDate = Date()
        let formattedDate = dateFormatter.string(from: currentDate)
        
        let id = XMLNode.attribute(withName: "id", stringValue: formattedDate) as! XMLNode
        let name = XMLNode.attribute(withName: "name", stringValue: "swift-e2e-results - \(Date().formatted())") as! XMLNode
        
        root.addAttribute(id)
        root.addAttribute(name)
    }
    
    public func beforeFeature(_ feature: Feature) async throws {
        featureStart = Date()
        currentFeature = XMLElement(name: "testsuite")
        featureTests = 0
        featureFailures = 0
        
        let id = XMLNode.attribute(withName: "id", stringValue: feature.id) as! XMLNode
        let name = XMLNode.attribute(withName: "name", stringValue: feature.title) as! XMLNode
        
        currentFeature.addAttribute(id)
        currentFeature.addAttribute(name)
        
        root.addChild(currentFeature)
    }
    
    public func beforeScenario(_ scenario: Scenario) async throws {
        scenarioStart = Date()
        currentScenario = XMLElement(name: "testcase")
        
        let id = XMLNode.attribute(withName: "id", stringValue: scenario.id) as! XMLNode
        let name = XMLNode.attribute(withName: "name", stringValue: scenario.name) as! XMLNode
        
        currentScenario.addAttribute(id)
        currentScenario.addAttribute(name)
        
        currentFeature.addChild(currentScenario)
    }
    
    public func beforeStep(_ step: ConcreteStep) async throws {
    }
    
    public func action(_ action: ActionOutcome) async throws {
    }
    
    public func afterStep(_ stepOutcome: StepOutcome) async throws {
    }
    
    public func afterScenario(_ scenarioOutcome: ScenarioOutcome) async throws {
        featureTests += 1
        let delta = String(format: "%.4f seconds", Date().timeIntervalSince(scenarioStart))
        let time = XMLNode.attribute(withName: "time", stringValue: delta) as! XMLNode
        currentScenario.addAttribute(time)
        
        if (scenarioOutcome.failedStep != nil) {
            let failure = XMLElement(name: "failure")
            featureFailures += 1
            let message = XMLNode.attribute(withName: "message", stringValue: String(describing: scenarioOutcome.failedStep!.error!)) as! XMLNode
            let type = XMLNode.attribute(withName: "type", stringValue: "ERROR") as! XMLNode
            failure.addAttribute(message)
            failure.addAttribute(type)
            
            currentScenario.addChild(failure)
        }
    }
    
    public func afterFeature(_ featureOutcome: FeatureOutcome) async throws {
        let delta = String(format: "%.4f seconds", Date().timeIntervalSince(featureStart))
        let time = XMLNode.attribute(withName: "time", stringValue: delta) as! XMLNode
        let tests = XMLNode.attribute(withName: "tests", stringValue: String(featureTests)) as! XMLNode
        let failures = XMLNode.attribute(withName: "failures", stringValue: String(featureFailures)) as! XMLNode
        currentFeature.addAttribute(time)
        currentFeature.addAttribute(tests)
        currentFeature.addAttribute(failures)
        
        totalTests += featureTests
        totalFailures += featureFailures
    }
    
    public func afterFeatures(_ featuresOutcome: [FeatureOutcome]) async throws {
        let delta = String(format: "%.4f seconds", Date().timeIntervalSince(testSuitesStart))
        let time = XMLNode.attribute(withName: "time", stringValue: delta) as! XMLNode
        let tests = XMLNode.attribute(withName: "tests", stringValue: String(totalTests)) as! XMLNode
        let failures = XMLNode.attribute(withName: "failures", stringValue: String(totalFailures)) as! XMLNode
        
        root.addAttribute(time)
        root.addAttribute(tests)
        root.addAttribute(failures)
        
        let outputPath = TestConfiguration.shared().targetDirectory().appendingPathComponent("junit.xml")
        let prettyPrintOptions: XMLNode.Options = [.nodePrettyPrint]
        let prettyPrintedData = xml.xmlData(options: prettyPrintOptions)
        let summary = String(data: prettyPrintedData, encoding: .utf8)
        try summary!.write(to: outputPath, atomically: true, encoding: .utf8)
    }
}
