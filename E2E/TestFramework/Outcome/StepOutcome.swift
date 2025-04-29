import Foundation

public class StepOutcome {
    let step: ConcreteStep
    var error: Error?
    
    init(_ step: ConcreteStep, _ error: Error? = nil) {
        self.step = step
        self.error = error
    }
}
