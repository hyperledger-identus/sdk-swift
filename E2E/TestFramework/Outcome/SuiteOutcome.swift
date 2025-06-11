import Foundation

public class SuiteOutcome {
    var featureOutcomes: [FeatureOutcome] = []
    public var startTime: Date?
    public var endTime: Date?
    
    public var passedFeatures: [FeatureOutcome] {
        featureOutcomes.filter { $0.status == .passed }
    }
    public var failedFeatures: [FeatureOutcome] {
        featureOutcomes.filter { $0.status == .failed }
    }
    public var brokenFeatures: [FeatureOutcome] {
        featureOutcomes.filter { $0.status == .broken }
    }
    public var skippedFeatures: [FeatureOutcome] {
        featureOutcomes.filter { $0.status == .skipped }
    }

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
}
