import Foundation
import XCTest
import SwiftHamcrest

open class TestConfiguration: ITestConfiguration {
    public static var started = false
    public static var shared = { instance! }
    
    public var environment: [String: String] = [:]
    private static var instance: TestConfiguration? = nil
    private static var actors: [String: Actor] = [:]
    
    private var assertionFailure: (String, StaticString, UInt)? = nil
    private var actionFailure: (String, Error, StaticString, UInt)? = nil
    private var reporters: [Reporter] = []
    
    internal var suiteOutcome: SuiteOutcome = SuiteOutcome()
    private var features: [Feature.Type] = []
    private var steps: [Steps] = []
    
    private var currentFeatureOutcome: FeatureOutcome? = nil
    private var currentScenario: Scenario? = nil
    
    public init(bundlePath: String) {
        self.environment = readEnvironmentVariables(bundlePath: bundlePath)
    }
    
    open class func createInstance() -> TestConfiguration {
        fatalError("Configuration must implement createInstance method")
    }
    
    open func targetDirectory() -> URL {
        fatalError("Configuration must implement targetDirectory method")
    }
    
    open func createActors() async throws -> [Actor]  {
        fatalError("Configuration must implement createActors method")
    }
    
    open func setUp() async throws {
        fatalError("Configuration must implement setUp method")
    }
    
    open func tearDown() async throws {
        fatalError("Configuration must implement tearDown method")
    }
    
    @MainActor
    static func setUpInstance() async throws {
        if (instance == nil) {
            XCTestObservationCenter.shared.addTestObserver(TestObserver())
        }
        started = true
        try await setUpConfigurationInstance()
        
    }
    
    /// Refresh for each feature
    func tearDownInstance() async throws {
        try await tearDownSteps()
        try await tearDownActors()
        try await tearDownConfigurationInstance()
    }
    
    open func createReporters() async throws -> [Reporter] {
        return [JunitReporter(), HtmlReporter(), DotReporter()]
    }
    
    /// Main function that runs feature, scenario and steps
    public func run(_ feature: Feature, _ scenario: Scenario?) async throws {
        currentScenario = scenario
        try await beforeFeature(feature)
        try await beforeScenario(scenario!)
        let scenarioOutcome = try await runSteps(scenario!)
        try await afterScenario(scenarioOutcome)
    }
    
    public func beforeFeature(_ feature: Feature) async throws {
        let type: Feature.Type = type(of: feature)
        
        if (features.contains(where: { $0 == type })) {
            return
        }
        
        features.append(type)
        currentFeatureOutcome = FeatureOutcome(feature: feature)
        currentFeatureOutcome!.start()
        suiteOutcome.featureOutcomes.append(currentFeatureOutcome!)
        
        try await report(.BEFORE_FEATURE, feature)
    }
    
    public func beforeScenario(_ scenario: Scenario) async throws {
        try await report(.BEFORE_SCENARIO, scenario)
        try await self.setUpActors()
    }
    
    public func beforeStep(_ step: ConcreteStep) async throws {
        try await report(.BEFORE_STEP, step)
    }
    
    func runSteps(_ scenario: Scenario) async throws -> ScenarioOutcome {
        if scenario.disabled {
            return ScenarioOutcome(scenario)
        }
        
        let scenarioOutcome = ScenarioOutcome(scenario)
        scenarioOutcome.start()
        
        for step in scenario.steps {
            var determinedStepStatus: TestStatus
            var stepError: Error? = nil
            let stepOutcome = StepOutcome(step)
            try await report(.BEFORE_STEP, step)
            do {
                stepOutcome.start()
                try await StepRegistry.run(step)
                stepOutcome.end()
                if let currentAssertionFailure = assertionFailure {
                    self.assertionFailure = nil
                    let message = currentAssertionFailure.0
                    let file = currentAssertionFailure.1
                    let line = currentAssertionFailure.2
                    XCTFail(message, file: file, line: line)
                    stepError = Assertion.AssertionError(
                        message: message,
                        file: file,
                        line: line
                    )
                    determinedStepStatus = .failed
                } else if let currentActionFailure = actionFailure {
                    self.actionFailure = nil
                    let message = currentActionFailure.0
                    let error = currentActionFailure.1
                    let file = currentActionFailure.2
                    let line = currentActionFailure.3
                    XCTFail(message, file: file, line: line)
                    stepError = ActorError.actionError(
                        message: message,
                        error: error,
                        file: file,
                        line: line
                    )
                    determinedStepStatus = .broken
                } else {
                    determinedStepStatus = .passed
                }
            } catch let assertionErr as Assertion.AssertionError {
                stepError = assertionErr
                determinedStepStatus = .failed
            } catch let error as BaseError {
                XCTFail(error.localizedDescription, file: error.file, line: error.line)
                stepError = error
                determinedStepStatus = .failed
            } catch {
                currentScenario!.fail(file: step.file, line: step.line, message: String(describing: error))
                stepError = error
                determinedStepStatus = .broken
            }
            
            stepOutcome.status = determinedStepStatus
            stepOutcome.error = stepError
            scenarioOutcome.steps.append(stepOutcome)
            try await report(.AFTER_STEP, stepOutcome)
            
            if stepOutcome.status == .failed || stepOutcome.status == .broken {
                scenarioOutcome.status = stepOutcome.status
                scenarioOutcome.error = stepOutcome.error
                break
            }
            
            if stepOutcome.status == .pending {
                scenarioOutcome.status = stepOutcome.status
                break
            }
        }
        
        actionFailure = nil
        scenarioOutcome.end()
        return scenarioOutcome
        
    }
    
    func executeAction<T>(
        _ message: String,
        _ file: StaticString,
        _ line: UInt,
        _ closure: () async throws -> T
    ) async throws -> T {
        /// skip if any previous action failed
        if (actionFailure != nil) {
            throw actionFailure!.1
        }
        
        let actionOutcome = ActionOutcome(action: message)
        actionOutcome.start()
        do {
            let result = try await closure()
            actionOutcome.status = .passed
            actionOutcome.end()
            try await TestConfiguration.shared().report(.ACTION, actionOutcome)
            return result
        } catch {
            actionOutcome.status = .failed
            actionOutcome.error = error
            actionOutcome.end()
            try await TestConfiguration.shared().report(.ACTION, actionOutcome)
            actionFailure = (message: message, error: error, file: file, line: line)
            throw error
        }
    }

    public func afterStep(_ stepOutcome: StepOutcome) async throws {
        try await report(.AFTER_STEP, stepOutcome)
    }
    
    public func afterScenario(_ scenarioOutcome: ScenarioOutcome) async throws {
        guard let currentFeatureOut = self.currentFeatureOutcome else {
            print("TestConfiguration Error: currentFeatureOutcome is nil in afterScenario for scenario: \(scenarioOutcome.scenario.name)")
            return
        }
        currentFeatureOut.scenarioOutcomes.append(scenarioOutcome)
        try await report(.AFTER_SCENARIO, scenarioOutcome)
        try await tearDownActors()
    }
    
    public func afterFeature(_ featureOutcome: FeatureOutcome) async throws {
        currentFeatureOutcome!.end()
        try await report(.AFTER_FEATURE, featureOutcome)
    }
    
    public func afterFeatures(_ featuresOutcome: [FeatureOutcome]) async throws {
        try await report(.AFTER_FEATURES, featuresOutcome)
    }
    
    public func endCurrentFeature() async throws {
        guard let featureOutcomeToFinalize = self.currentFeatureOutcome else {
            print("TestConfiguration Error: currentFeatureOutcome is nil in endCurrentFeature.")
            return
        }
        var possibleFeatureError: Error? = nil
        do {
            try await self.tearDownInstance()
        } catch {
            possibleFeatureError = error
        }

        featureOutcomeToFinalize.finalizeOutcome(featureLevelError: possibleFeatureError)
        try await self.afterFeature(featureOutcomeToFinalize)
    }
    
    /// signals the suite has ended
    public func end() {
        let semaphore = DispatchSemaphore(value: 0)
        Task.detached {
            self.suiteOutcome.end()
            try await self.afterFeatures(self.suiteOutcome.featureOutcomes)
            try await self.tearDownInstance()
            semaphore.signal()
        }
        semaphore.wait()
    }
    
    public func report(_ phase: Phase, _ object: Any) async throws {
        for reporter in reporters {
            switch(phase) {
            case .BEFORE_FEATURE:
                try! await reporter.beforeFeature(object as! Feature)
            case .AFTER_FEATURE:
                try! await reporter.afterFeature(object as! FeatureOutcome)
            case .BEFORE_SCENARIO:
                try! await reporter.beforeScenario(object as! Scenario)
            case .AFTER_SCENARIO:
                try! await reporter.afterScenario(object as! ScenarioOutcome)
            case .BEFORE_STEP:
                try! await reporter.beforeStep(object as! ConcreteStep)
            case .AFTER_STEP:
                try! await reporter.afterStep(object as! StepOutcome)
            case .ACTION:
                try! await reporter.action(object as! ActionOutcome)
            case .AFTER_FEATURES:
                try! await reporter.afterFeatures(object as! [FeatureOutcome])
            }
            fflush(stdout)
            fflush(stderr)
        }
    }
    
    private func setUpActors() async throws {
        let actors = try await createActors()
        for actor in actors {
            TestConfiguration.actors[actor.name] = actor
        }
    }
    
    private func tearDownActors() async throws {
        for actor in TestConfiguration.actors.values {
            try await actor.tearDown()
        }
        TestConfiguration.actors.removeAll()
    }
    
    private func setUpSteps() async throws {
        let subclasses = ClassLocator.subclasses(of: Steps.self)
        for subclass in subclasses {
            if (subclass != Steps.self) {
                steps.append(try await (subclass as! Steps.Type).init())
            }
        }
    }
    
    private func tearDownSteps() async throws {
        for step in steps {
            try await step.tearDown()
        }
    }
    
    private static func setUpConfigurationInstance() async throws {
        if (self.instance != nil) {
            return
        }
        
        let subclasses = ClassLocator.subclasses(of: TestConfiguration.self).filter { $0 != TestConfiguration.self }
        if (subclasses.count == 0) {
            fatalError("No configuration class found. Create a class that extends CucumberConfig class.")
        }
        if (subclasses.count > 1) {
            fatalError("More than 1 configuration class found.")
        }
        
        let instanceType = (subclasses[0] as! ITestConfiguration.Type)
        
        // force as own instance
        let instance = instanceType.createInstance()
        instance.suiteOutcome.start()
        self.instance = instance
        
        do {
            try await instance.setUp()
            try await instance.setUpReporters()
            try await instance.setUpSteps()
        } catch {
            throw ConfigurationError.setup(message: error.localizedDescription)
        }
        
        /// setup hamcrest to update variable if failed
        HamcrestReportFunction = { message, file, line in
            instance.assertionFailure = (message, file, line)
        }
        
        let fileManager = FileManager.default
        /// delete target folder
        do {
            try fileManager.removeItem(at: instance.targetDirectory())
        } catch {
        }
        /// recreate it
        do {
            try fileManager.createDirectory(at: instance.targetDirectory(), withIntermediateDirectories: true, attributes: nil)
        } catch {
        }
    }
    
    private func setUpReporters() async throws {
        reporters = try await  createReporters()
    }
    
    private func tearDownConfigurationInstance() async throws {
        try await tearDown()
    }
    
    private func readEnvironmentVariables(bundlePath: String) -> [String: String] {
        var environment: [String: String] = [:]
        
        // load property file
        if let path = Bundle(path: bundlePath)?.path(forResource: "properties", ofType: "plist", inDirectory: "Resources") {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                if let dictionary = try? (PropertyListSerialization.propertyList(from: data, options: [], format: nil) as! [String: String]) {
                    dictionary.forEach {
                        environment[$0.key] = $0.value
                    }
                }
            }
        }
        // overrides if any environment variable is available
        ProcessInfo.processInfo.environment.forEach {
            environment[$0.key] = $0.value
        }
        return environment
    }
    
    /// Default parsers
    @ParameterParser
    var actorParser = { (actor: String) in
        if (!actors.contains(where: { $0.key == actor })) {
            actors[actor] = Actor(actor)
        }
        return actors[actor]!
    }
    
    @ParameterParser
    var stringParser = { (string: String) in
        return string
    }
    
    @ParameterParser
    var intParser = { (int: String) in
        return Int(int)!
    }
}
