import Foundation

open class BaseError: Error, LocalizedError, CustomStringConvertible {
    public let file: StaticString
    public let line: UInt
    
    public var errorDescription: String?
    public var failureReason: String?
    public var recoverySuggestion: String?
    public var helpAnchor: String?
    
    private let providedMessage: String
    private let errorTypeString: String
    
    public var description: String {
        return self.errorDescription ?? "Undefined error: \(self.errorTypeString) - \(self.providedMessage)"
    }
    
    public init(message: String, error: String, file: StaticString = #file, line: UInt = #line) {
        self.file = file
        self.line = line
        self.providedMessage = message
        self.errorTypeString = error
        
        let fileName = URL(fileURLWithPath: String(describing: file)).lastPathComponent
        
        self.errorDescription = "\(self.errorTypeString): \(self.providedMessage) (at \(fileName):\(line))"
        self.failureReason = "An issue occurred related to '\(self.errorTypeString)'."
    }
}
