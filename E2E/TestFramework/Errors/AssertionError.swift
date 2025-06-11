import Foundation

class Assertion {
    class AssertionError: BaseError {
        init(message: String, file: StaticString = #file, line: UInt = #line) {
            super.init(
                message: message,
                error: "Assertion failure",
                file: file,
                line: line
            )
        }
    }

    class TimeoutError: BaseError {
        let timeout: Int

        init(timeout: Int, message: String = "time limit exceeded", file: StaticString = #file, line: UInt = #line) {
            self.timeout = timeout
            super.init(
                message: message,
                error: "Timeout reached (\(timeout))s",
                file: file,
                line: line
            )
        }
    }
}

