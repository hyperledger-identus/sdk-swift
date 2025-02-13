import Foundation

public class DebugReporter: Reporter {
    private var actions: [String] = []
    private var debug: Bool = true
    
    public required init() {}
    
    public func beforeFeature(_ feature: Feature) async throws {
        if debug { print("Before Feature:", feature.title()) }
    }
    
    public func beforeScenario(_ scenario: Scenario) async throws {
        if debug { print("Before Scenario:", scenario.title) }
    }
    
    public func beforeStep(_ step: ConcreteStep) async throws {
        print("Before Step:", step.action)
    }
    
    public func action(_ action: ActionOutcome) async throws {
        actions.append(action.action)
    }
    
    public func afterStep(_ stepOutcome: StepOutcome) async throws {
        print("After Step", stepOutcome.step.action)
        actions.forEach { action in
            print("Action", action)
        }
        actions = []
    }
    
    public func afterScenario(_ scenarioOutcome: ScenarioOutcome) async throws {
        print("After Scenario", scenarioOutcome.scenario.title)
    }
    
    public func afterFeature(_ featureOutcome: FeatureOutcome) async throws {
        print("After Feature", featureOutcome.feature.title())
    }
    
    public func afterFeatures(_ featuresOutcome: [FeatureOutcome]) async throws {
        print("After Features", featuresOutcome.count)
    }
}
