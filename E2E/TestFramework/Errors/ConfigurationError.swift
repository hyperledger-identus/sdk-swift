open class ConfigurationError {
    public final class setup: BaseError {
        public init(message: String, file: StaticString = #file, line: UInt = #line) {
            super.init(message: message, error: "Configuration error", file: file, line: line)
        }
    }
    
    public final class missingScenario: Error, CustomStringConvertible {
        public var errorDescription: String
        public var failureReason: String = "Missing scenario"
        
        public init(_ message: String) {
            self.errorDescription = message
        }
        
        public var description: String {
            return self.errorDescription
        }
    }
}
