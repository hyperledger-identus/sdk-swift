import Foundation

public protocol Reporter {
    init()
    
    func beforeFeature(_ feature: Feature) async throws
    func beforeScenario(_ scenario: Scenario) async throws
    func beforeStep(_ step: ConcreteStep) async throws
    func action(_ action: ActionOutcome) async throws
    func afterStep(_ stepOutcome: StepOutcome) async throws
    func afterScenario(_ scenarioOutcome: ScenarioOutcome) async throws
    func afterFeature(_ featureOutcome: FeatureOutcome) async throws
    func afterFeatures(_ featuresOutcome: [FeatureOutcome]) async throws
}
