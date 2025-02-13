import Foundation

/**
 Concrete step
 */
public class ConcreteStep {
    let id: String
    var context: String = ""
    var action: String = ""
    var line: UInt? = nil
    var file: StaticString? = nil
    
    init() {
        id = UUID().uuidString
    }

    static func == (lhs: ConcreteStep, rhs: ConcreteStep) -> Bool {
        return lhs.context == rhs.context && lhs.action == rhs.action
    }
}
