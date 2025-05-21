import Foundation

public class FeatureOutcome {
    public let feature: Feature
    public var scenarioOutcomes: [ScenarioOutcome] = []
    public var status: TestStatus
    public var error: Error?
    public var startTime: Date?
    public var endTime: Date?

    func start() {
        startTime = Date()
    }
    
    func end() {
        endTime = Date()
    }
    
    public var duration: TimeInterval? {
        guard let start = startTime, let end = endTime else { return nil }
        return end.timeIntervalSince(start)
    }

    public var passedScenarios: [ScenarioOutcome] {
        scenarioOutcomes.filter { $0.status == .passed }
    }
    public var failedScenarios: [ScenarioOutcome] {
        scenarioOutcomes.filter { $0.status == .failed }
    }
    public var brokenScenarios: [ScenarioOutcome] {
        scenarioOutcomes.filter { $0.status == .broken }
    }
    public var skippedScenarios: [ScenarioOutcome] {
        scenarioOutcomes.filter { $0.status == .skipped }
    }

    public init(feature: Feature, startTime: Date = Date()) {
        self.feature = feature
        self.startTime = startTime
        self.status = .passed
    }

    public func finalizeOutcome(featureLevelError: Error? = nil) {
        self.endTime = Date() // Set end time when finalizing

        if let explicitError = featureLevelError {
            self.error = explicitError
        }
        
        if self.error != nil {
            self.status = .broken
            return
        }

        if scenarioOutcomes.isEmpty {
            return
        }

        if scenarioOutcomes.contains(where: { $0.status == .broken }) {
            self.status = .broken
        } else if scenarioOutcomes.contains(where: { $0.status == .failed }) {
            self.status = .failed
        } else if scenarioOutcomes.allSatisfy({ $0.status == .skipped }) {
            self.status = .skipped
        } else if scenarioOutcomes.allSatisfy({ $0.status == .passed || $0.status == .skipped }) {
            self.status = .passed
        } else {
            // This case should ideally not be reached if the above logic is complete.
            // Could default to .broken if there's an unexpected mix.
            print("Warning: FeatureOutcome for '\(feature.title())' has an undetermined status mix.")
            self.status = .broken // Default for unexpected mixed states
        }
    }
}
