import Foundation
import XCTest

public class Scenario {
    let id = UUID().uuidString
    var name: String
    var steps: [ConcreteStep] = []
    var disabled: Bool = false
    var feature: Feature?
    var parameters: [String: String]?
    var tags: [String] = []
    
    private var lastContext: String = ""
    
    public init(_ title: String, parameters: [String: String] = [:]) {
        self.name = title
        self.parameters = parameters
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
    
    public func tags(_ tags: String...) -> Scenario {
        self.tags.append(contentsOf: tags)
        return self
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
    
    public func disable() -> Scenario {
        self.disabled = true
        return self
    }
}
