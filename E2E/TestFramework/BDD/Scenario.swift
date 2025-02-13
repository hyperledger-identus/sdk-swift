import Foundation
import XCTest

public class Scenario {
    let id = UUID().uuidString
    var title: String
    var steps: [ConcreteStep] = []
    var pass: Bool = false
    var error: Error? = nil
    
    private var lastContext: String = ""
    
    public init(_ title: String) {
        self.title = title
    }
    
    public func fail(file: StaticString?, line: UInt?, message: String) {
        if (file != nil) {
            XCTFail(message, file: file!, line: line!)
        } else {
            XCTFail(message)
        }
    }

    private func addStep(_ step: String) {
        let stepInstance = ConcreteStep()
        stepInstance.context = lastContext
        stepInstance.action = step
        steps.append(stepInstance)
    }
    
    public func given(_ step: String) -> Scenario {
        lastContext = "Given"
        addStep(step)
        return self
    }
    
    public func when(_ step: String) -> Scenario {
        lastContext = "When"
        addStep(step)
        return self
    }
    
    public func then(_ step: String) -> Scenario {
        lastContext = "Then"
        addStep(step)
        return self
    }
    
    public func but(_ step: String) -> Scenario {
        lastContext = "But"
        addStep(step)
        return self
    }
    
    public func and(_ step: String) -> Scenario {
        if (lastContext.isEmpty) {
            fatalError("Trying to add an [and] step without previous context.")
        }
        addStep(step)
        return self
    }
}
