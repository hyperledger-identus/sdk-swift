import Foundation

public class SummaryReporter: Reporter {
    required public init () {
    }
    
    public func beforeFeature(_ feature: Feature) async throws {
    }
    
    public func beforeScenario(_ scenario: Scenario) async throws {
    }
    
    public func beforeStep(_ step: ConcreteStep) async throws {
    }
    
    public func action(_ action: ActionOutcome) async throws {
    }
    
    public func afterStep(_ stepOutcome: StepOutcome) async throws {
    }
    
    public func afterScenario(_ scenarioOutcome: ScenarioOutcome) async throws {
    }
    
    public func afterFeature(_ featureOutcome: FeatureOutcome) async throws {
    }
    
    public func afterFeatures(_ featuresOutcome: [FeatureOutcome]) async throws {
        var totalFeaturesExecuted = 0
        var featuresPassed = 0
        var featuresFailed = 0
        var featuresBroken = 0
        var featuresSkipped = 0
        var featuresPending = 0
        
        var totalScenariosExecuted = 0
        var scenariosPassed = 0
        var scenariosFailed = 0
        var scenariosBroken = 0
        var scenariosSkipped = 0
        var scenariosPending = 0
        
        let suiteObservedStartTime = featuresOutcome.first?.startTime
        
        print("\n\n===================================")
        print("     TEST EXECUTION SUMMARY")
        print("===================================\n")
        
        for featureOutcome in featuresOutcome { // Corrected Swift loop syntax
            totalFeaturesExecuted += 1
            let featureTitle = featureOutcome.feature.title
            let featureStatusString = featureOutcome.status.rawValue.uppercased()
            let featureDurationString = String(format: "%.2fs", featureOutcome.duration ?? 0.0)
            
            print("FEATURE: \(featureTitle)")
            print("  Status: \(featureStatusString)")
            print("  Duration: \(featureDurationString)")
            
            if featureOutcome.status == .failed || featureOutcome.status == .broken {
                if let error = featureOutcome.error { // Feature-level error
                    print("  Error: \(error.localizedDescription)")
                }
            }
            
            switch featureOutcome.status {
            case .passed: featuresPassed += 1
            case .failed: featuresFailed += 1
            case .broken: featuresBroken += 1
            case .skipped: featuresSkipped += 1
            case .pending: featuresPending += 1
            }
            
            let scenariosInFeature = featureOutcome.scenarioOutcomes.count
            let passedInFeature = featureOutcome.passedScenarios.count
            let failedInFeature = featureOutcome.failedScenarios.count
            let brokenInFeature = featureOutcome.brokenScenarios.count
            let skippedInFeature = featureOutcome.skippedScenarios.count
            let pendingInFeature = featureOutcome.scenarioOutcomes.filter { $0.status == .pending }.count
            
            totalScenariosExecuted += scenariosInFeature
            scenariosPassed += passedInFeature
            scenariosFailed += failedInFeature
            scenariosBroken += brokenInFeature
            scenariosSkipped += skippedInFeature
            scenariosPending += pendingInFeature
            
            print("  Scenarios (\(scenariosInFeature) total):")
            print("    Passed: \(passedInFeature), Failed: \(failedInFeature), Broken: \(brokenInFeature), Skipped: \(skippedInFeature), Pending: \(pendingInFeature)")
            
            let unsuccessfulScenarios = featureOutcome.scenarioOutcomes.filter {
                $0.status == .failed || $0.status == .broken
            }
            
            if !unsuccessfulScenarios.isEmpty {
                print("  Unsuccessful Scenarios Details:")
                for scenarioOutcome in unsuccessfulScenarios {
                    let scenarioStatusStr = scenarioOutcome.status.rawValue.uppercased()
                    let scenarioDurationStr = String(format: "%.2fs", scenarioOutcome.duration ?? 0.0)
                    print("    [\(scenarioStatusStr)] \(scenarioOutcome.scenario.name) (\(scenarioDurationStr)), caused by")
                    if let error = scenarioOutcome.error ?? scenarioOutcome.failedStep?.error {
                        if (!error.localizedDescription.starts(with: "The operation couldn’t be completed.")) {
                            print("        \(error.localizedDescription)")
                        } else {
                            print("        \(error)")
                        }
                    }
                }
            }
            print("-----------------------------------")
        }
        
        print("\n====== OVERALL SUITE RESULTS ======\n")
        print("Total Features Executed: \(totalFeaturesExecuted)")
        print("  Features Passed:   \(featuresPassed)")
        print("  Features Failed:   \(featuresFailed)")
        print("  Features Broken:   \(featuresBroken)")
        print("  Features Skipped: \(featuresSkipped)")
        print("  Features Pending: \(featuresPending)")
        print("---")
        print("Total Scenarios Executed: \(totalScenariosExecuted)")
        print("  Scenarios Passed:   \(scenariosPassed)")
        print("  Scenarios Failed:   \(scenariosFailed)")
        print("  Scenarios Broken:   \(scenariosBroken)")
        print("  Scenarios Skipped: \(scenariosSkipped)")
        print("  Scenarios Pending: \(scenariosPending)")
        print("---")
        
        if let startTime = suiteObservedStartTime, let lastFeature = featuresOutcome.last, let endTime = lastFeature.endTime {
            let suiteDuration = endTime.timeIntervalSince(startTime)
            print(String(format: "Approx. Total Suite Duration: %.2fs", suiteDuration))
        } else if totalFeaturesExecuted > 0 { // Fallback if precise start/end is not available for the whole suite
            let sumOfFeatureDurations = featuresOutcome.reduce(0.0) { $0 + ($1.duration ?? 0.0) }
            print(String(format: "Approx. Total Suite Duration (Sum of Features): %.2fs", sumOfFeatureDurations))
        } else {
            print("Approx. Total Suite Duration: N/A (No features run or timing unavailable)")
        }
        
        print("\n===================================")
        print("         END OF SUMMARY")
        print("===================================\n")
    }
}
