import Foundation

public protocol ITestConfiguration {
    static var shared: () -> ITestConfiguration {get}
    static func createInstance() -> ITestConfiguration

    func run(_ feature: Feature, _ currentScenario: Scenario) async throws
    
    /// setup
    func setUp() async throws
    
    /// teardown
    func tearDown() async throws

    /// phases
    func beforeFeature(_ feature: Feature) async throws
    func beforeScenario(_ scenario: Scenario) async throws
    func beforeStep(_ step: ConcreteStep) async throws
    func afterStep(_ stepOutcome: StepOutcome) async throws
    func afterScenario(_ scenarioOutcome: ScenarioOutcome) async throws
    func afterFeature(_ featureOutcome: FeatureOutcome) async throws
    func afterFeatures(_ featuresOutcome: [FeatureOutcome]) async throws
    
    func endCurrentFeature() async throws
    func end()
    
    /// methods
    func createActors() async throws -> [Actor]
    func createReporters() async throws -> [Reporter]
    func report(_ phase: Phase, _ object: Any) async throws
    func targetDirectory() -> URL

}
