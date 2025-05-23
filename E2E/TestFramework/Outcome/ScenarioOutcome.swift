import Foundation

public class ScenarioOutcome {
    let scenario: Scenario
    var steps: [StepOutcome] = []
    var status: TestStatus
    var error: Error?
    public var startTime: Date?
    public var endTime: Date?

    var failedStep: StepOutcome? {
        return steps.first(where: { $0.status == .failed || $0.status == .broken })
    }

    init(_ scenario: Scenario) {
        self.scenario = scenario
        self.status = .passed
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
