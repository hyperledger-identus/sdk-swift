import Foundation

public class DotReporter: Reporter {
    required public init () {
    }
    
    private func printDot() {
        print(".", terminator: "")
    }
    
    public func beforeFeature(_ feature: Feature) async throws {
        printDot()
    }
    
    public func beforeScenario(_ scenario: Scenario) async throws {
        printDot()
    }
    
    public func beforeStep(_ step: ConcreteStep) async throws {
        printDot()
    }
    
    public func action(_ action: ActionOutcome) async throws {
        printDot()
    }
    
    public func afterStep(_ stepOutcome: StepOutcome) async throws {
        printDot()
    }
    
    public func afterScenario(_ scenarioOutcome: ScenarioOutcome) async throws {
        print()
    }
    
    public func afterFeature(_ featureOutcome: FeatureOutcome) async throws {
    }
    
    public func afterFeatures(_ featuresOutcome: [FeatureOutcome]) async throws {
        print("Executed", featuresOutcome.count, "features")
        for featureOutcome in featuresOutcome {
            print("  ", "Feature:", featureOutcome.feature.title())
            for scenarioOutcome in featureOutcome.scenarioOutcomes {
                print(
                    "    ",
                    scenarioOutcome.failedStep != nil ? "(fail)" : "(pass)",
                    scenarioOutcome.scenario.name
                )
                if (scenarioOutcome.failedStep != nil) {
                    let failedStep = scenarioOutcome.failedStep!
                    print("          ", failedStep.error!)
                    print("           at step: \"\(failedStep.step.action)\"")
                }
            }
        }
    }
}
