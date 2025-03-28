import Foundation
import XCTest

public class ParameterizedScenario: Scenario {
    public var parameters: [[String: String]] = [[:]]

    public func parameters(_ parameters: [[String: String]]) -> Scenario {
        self.parameters = parameters
        return self
    }
    
    public func build() -> [Scenario] {
        var scenarios: [Scenario] = []
        
        parameters.forEach { parameters in
            let scenario = Scenario(replace(line: self.title, parameters: parameters))
            scenario.steps = self.steps.map { step in
                let newStep = ConcreteStep()
                newStep.context = step.context
                newStep.action = replace(line: step.action, parameters: parameters)
                return newStep
            }
            scenarios.append(scenario)
        }
        
        return scenarios
    }
    
    private func replace(line: String, parameters: [String: String]) -> String {
        var line = line
        for (placeholder, value) in parameters {
            line = line.replacingOccurrences(of: "<\(placeholder)>", with: value)
        }
        return line
    }
}
