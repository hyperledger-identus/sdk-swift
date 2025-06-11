import Foundation

public class StepOutcome {
    let step: ConcreteStep
    var status: TestStatus
    var error: Error?
    public var startTime: Date?
    public var endTime: Date?

    init(_ step: ConcreteStep) {
        self.step = step
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
