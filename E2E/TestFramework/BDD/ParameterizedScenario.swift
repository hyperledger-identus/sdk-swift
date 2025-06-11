import Foundation
import XCTest

public class ParameterizedScenario: Scenario {
    public var table: [[String: String]] = [[:]]

    public func table(_ table: [[String: String]]) -> Scenario {
        self.table = table
        return self
    }
    
    public func build() -> [Scenario] {
        var scenarios: [Scenario] = []
        
        table.forEach { parameters in
            let scenario = Scenario(replace(line: self.name, parameters: parameters), parameters: parameters)
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
