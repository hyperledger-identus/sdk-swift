import Foundation

enum StepError {
    class parameterTypeDoesNotMatch: BaseError {
        init(_ step: String, expected: String, actual: String, file: StaticString = #file, line: UInt = #line) {
            let message = "Parameter mismatch in step '\(step)': Expected a parameter matching '\(expected)', but found '\(actual)'."
            super.init(message: message, error: "Parameter doesn't match", file: file, line: line)
        }
    }
    
    class notFound: BaseError {
        init(_ stepPattern: String, file: StaticString = #file, line: UInt = #line) {
            let message = "No step definition found matching the pattern: '\(stepPattern)'. Please ensure a corresponding step implementation exists."
            super.init(message: message, error: "Step definition not found", file: file, line: line)
        }
    }
    
    class typeNotFound: BaseError {
        init(typeName: String? = nil, forStep: String? = nil, file: StaticString = #file, line: UInt = #line) {
            var message = "A suitable parameter parser or type was not found"
            if let type = typeName {
                message += " for type '\(type)'"
            }
            if let step = forStep {
                message += " in step '\(step)'"
            }
            message += "."
            super.init(message: message, error: "Parameter type not found", file: file, line: line)
        }
    }
}
