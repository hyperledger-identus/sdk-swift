import Foundation

public class HtmlReporter: Reporter {
    private let pass = "(✔)"
    private let fail = "(✘)"
    
    private var currentFeature: Feature? = nil
    private var currentScenario: Scenario? = nil
    private var currentStep: ConcreteStep? = nil
    private var currentId: String? = nil
    
    private var actions: [String: [ActionOutcome]] = [:]
    
    public required init() {}
    
    public func beforeFeature(_ feature: Feature) async throws {
        currentFeature = feature
    }
    
    public func beforeScenario(_ scenario: Scenario) async throws {
        currentScenario = scenario
    }
    
    public func beforeStep(_ step: ConcreteStep) async throws {
        currentStep = step
        currentId = currentFeature!.id + currentScenario!.id + step.id
    }
    
    public func action(_ actionOutcome: ActionOutcome) async throws {
        if (actions[currentId!] == nil) {
            actions[currentId!] = []
        }
        actions[currentId!]!.append(actionOutcome)
    }
    
    public func afterStep(_ stepOutcome: StepOutcome) async throws {
        currentStep = nil
    }
    
    public func afterScenario(_ scenarioOutcome: ScenarioOutcome) async throws {
        currentScenario = nil
    }
    
    public func afterFeature(_ featureOutcome: FeatureOutcome) async throws {
        currentFeature = nil
    }
    
    public func afterFeatures(_ featuresOutcome: [FeatureOutcome]) async throws {
        let htmlReport: HtmlReport = HtmlReport()
        for featureOutcome in featuresOutcome {
            let featureReport = FeatureReport()
            featureReport.name = featureOutcome.feature.title()
            htmlReport.data.append(featureReport)
            
            for scenarioOutcome in featureOutcome.scenarioOutcomes {
                let scenarioReport = ScenarioReport()
                scenarioReport.name = scenarioOutcome.scenario.name
                featureReport.scenarios.append(scenarioReport)
                scenarioReport.status = scenarioOutcome.status.rawValue

                for stepOutcome in scenarioOutcome.steps {
                    let stepReport = StepReport()
                    stepReport.name = stepOutcome.step.action
                    scenarioReport.steps.append(stepReport)
                    
                    let stepId = featureOutcome.feature.id + scenarioOutcome.scenario.id + stepOutcome.step.id
                    if let stepActions = actions[stepId] {
                        for actionOutcome in stepActions {
                            let actionReport = ActionReport()
                            actionReport.action = actionOutcome.action
                            actionReport.status = actionOutcome.status.rawValue
                            stepReport.actions.append(actionReport)
                            if(actionOutcome.error != nil) {
                                break
                            }
                        }
                    }
                    if (stepOutcome.error != nil) {
                        stepReport.passed = false
                        stepReport.error = String(describing: scenarioOutcome.failedStep!.error!)
                        break
                    }
                }
                
                if (scenarioOutcome.failedStep != nil) {
                    featureReport.passed = false
                }
            }
        }
        
        let data = try JSONEncoder().encode(htmlReport.data)
        
        if let path = Bundle.module.path(forResource: "html_report", ofType: "html", inDirectory: "Resources") {
            if let htmlTemplateData = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                let htmlTemplate = String(data: htmlTemplateData, encoding: .utf8)!
                let report = htmlTemplate.replacingOccurrences(of: "{{data}}", with: String(data: data, encoding: .utf8)!)
                let outputPath = TestConfiguration.shared().targetDirectory().appendingPathComponent("report.html")
                try report.write(to: outputPath, atomically: true, encoding: .utf8)
            }
        }
    }
}

private class HtmlReport: Codable {
    var data: [FeatureReport] = []
}

private class FeatureReport: Codable {
    var name: String = ""
    var passed: Bool = true
    var scenarios: [ScenarioReport] = []
}

private class ScenarioReport: Codable {
    var name: String = ""
    var status: String = ""
    var steps: [StepReport] = []
}

private class StepReport: Codable {
    var name: String = ""
    var passed: Bool = true
    var error: String? = nil
    var actions: [ActionReport] = []
}

private class ActionReport: Codable {
    var action: String = ""
    var status: String = ""
}
