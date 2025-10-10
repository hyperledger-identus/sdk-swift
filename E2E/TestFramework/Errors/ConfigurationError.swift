open class ConfigurationError {
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
