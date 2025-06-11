import Foundation

public class ConsoleReporter: Reporter {
    private let pass = "(✔)"
    private let fail = "(✘)"

    private var actions: [String] = []

    required public init () {
    }
    
    public func beforeFeature(_ feature: Feature) async throws {
        print()
        print("---")
        print("Feature:", feature.title())
    }
    
    public func beforeScenario(_ scenario: Scenario) async throws {
        print("    ", scenario.name)
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
        print("    ", "Result:", scenarioOutcome.status.rawValue.uppercased())
    }
    
    public func afterFeature(_ featureOutcome: FeatureOutcome) async throws {
        print("Feature result", featureOutcome.status.rawValue.uppercased())
    }
    
    public func afterFeatures(_ featuresOutcome: [FeatureOutcome]) async throws {
    }
}
