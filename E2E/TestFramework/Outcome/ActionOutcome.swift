import Foundation

public class ActionOutcome {
    var action: String = ""
    var status: TestStatus
    var error: Error? = nil
    public var startTime: Date?
    public var endTime: Date?
//    var attachments: [AttachmentData]?

    init(action: String) {
        self.action = action
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
