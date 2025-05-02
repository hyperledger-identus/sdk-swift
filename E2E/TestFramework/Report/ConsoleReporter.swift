import Foundation

public class ConsoleReporter: Reporter {
    private let pass = "(✔)"
    private let fail = "(✘)"

    private var actions: [String] = []

    required public init () {
    }
    
    public func beforeFeature(_ feature: Feature) async throws {
        print()
        print("Feature:", feature.title())
    }
    
    public func beforeScenario(_ scenario: Scenario) async throws {
        print("    ", scenario.title)
    }
    
    public func beforeStep(_ step: ConcreteStep) async throws {
    }
    
    public func action(_ action: ActionOutcome) async throws {
        actions.append(action.action)
    }
    
    public func afterStep(_ stepOutcome: StepOutcome) async throws {
        let result = stepOutcome.error != nil ? fail : pass
        print("      ", result, stepOutcome.step.action)
        actions.forEach { action in
            print("            ", action)
        }
        actions = []
    }
    
    public func afterScenario(_ scenarioOutcome: ScenarioOutcome) async throws {
        let result = scenarioOutcome.failedStep != nil ? "FAIL" : "PASS"
        print("    ", "Result:", result)
    }
    
    public func afterFeature(_ featureOutcome: FeatureOutcome) async throws {
        print()
    }
    
    public func afterFeatures(_ featuresOutcome: [FeatureOutcome]) async throws {
    }
}
