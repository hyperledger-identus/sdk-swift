import Foundation

struct StepRegistry {

    static var runnableSteps: [String : StepRunner] = [:]
    
    static func run(_ concreteStep: ConcreteStep) async throws {
        let action = concreteStep.action
        var parameters: [String] = []
        var matchedStep: String?
        
        for stepMatcher in runnableSteps.keys {
            if let regex = try? NSRegularExpression(pattern: stepMatcher, options: []) {
                let range = NSRange(action.startIndex..., in: action)
                regex.enumerateMatches(in: action, options: [], range: range) { (match, _, _) in
                    if let match = match {
                        matchedStep = stepMatcher
                        for i in 1..<match.numberOfRanges {
                            let range = Range(match.range(at: i), in: action)!
                            let value = String(action[range])
                            parameters.append(value)
                        }
                    }
                }
            }
        }
        
        if (matchedStep == nil) {
            throw TestConfiguration.Failure.StepNotFound(step: action)
        }
        
        let runnable = runnableSteps[matchedStep!]!
        concreteStep.line = runnable.stepLine
        concreteStep.file = runnable.stepFile
        let parsers = runnable.parsers

        switch(parameters.count) {
        case 0:
            try await runnableSteps[matchedStep!]!.invoke(parameters: ())
        case 1:
            let parameter = try await parsers[0](parameters[0])
            try await runnable.invoke(parameters: parameter)
        case 2:
            let parameter = (
                try await parsers[0](parameters[0]),
                try await parsers[1](parameters[1])
            )
            try await runnableSteps[matchedStep!]!.invoke(parameters: parameter)
        case 3:
            let parameter = (
                try await parsers[0](parameters[0]),
                try await parsers[1](parameters[1]),
                try await parsers[2](parameters[2])
            )
            try await runnableSteps[matchedStep!]!.invoke(parameters: parameter)
        case 4:
            let parameter = (
                try await parsers[0](parameters[0]),
                try await parsers[1](parameters[1]),
                try await parsers[2](parameters[2]),
                try await parsers[3](parameters[3])
            )
            try await runnableSteps[matchedStep!]!.invoke(parameters: parameter)
        case 5:
            let parameter = (
                try await parsers[0](parameters[0]),
                try await parsers[1](parameters[1]),
                try await parsers[2](parameters[2]),
                try await parsers[3](parameters[3]),
                try await parsers[4](parameters[4])
            )
            try await runnableSteps[matchedStep!]!.invoke(parameters: parameter)
        default:
            fatalError("Maximum number of parameters for a step is 5.")
        }
    }

    static func addStep<T>(_ step: Step<T>) {
        let runnableStep = StepRunner(step)
        runnableSteps[runnableStep.stepMatcher] = runnableStep
    }
}
