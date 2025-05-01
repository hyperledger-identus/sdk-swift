import Foundation

class BaseError: Error, CustomStringConvertible {
    var description: String
    
    let message: String
    let error: String
    let file: StaticString
    let line: UInt

    fileprivate init(message: String, error: String, file: StaticString = #file, line: UInt = #line) {
        self.message = message
        self.error = error
        self.file = file
        self.line = line
        
        let fileName = URL(fileURLWithPath: String(describing: file)).lastPathComponent
        self.description = error + ": " + message + " (at \(fileName):\(line))"
    }
}

class Assertion {
    class AssertionError: BaseError {
        init(message: String, file: StaticString = #file, line: UInt = #line) {
            super.init(message: message,
                       error: "Assertion failure",
                       file: file,
                       line: line)
        }
    }

    class TimeoutError: BaseError {
        let timeout: Int

        init(timeout: Int, message: String = "time limit exceeded", file: StaticString = #file, line: UInt = #line) {
            self.timeout = timeout
            super.init(message: message, 
                       error: "Timeout reached (\(timeout))s",
                       file: file,
                       line: line)
        }
    }
}

