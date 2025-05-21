import Foundation

open class BaseError: Error, LocalizedError, CustomStringConvertible {
    public let file: StaticString
    public let line: UInt

    // Properties for LocalizedError conformance
    public var errorDescription: String?
    public var failureReason: String?
     public var recoverySuggestion: String? // Optional
     public var helpAnchor: String?       // Optional

    // Store the original components for constructing descriptions
    private let providedMessage: String
    private let errorTypeString: String // This was the 'error' parameter in your init

    // This is for CustomStringConvertible.
    // XCTest might use this when an error is thrown out of a test method.
    public var description: String {
        // We'll make this the same as errorDescription for consistency,
        // ensuring a detailed message is available.
        return self.errorDescription ?? "Undefined error: \(self.errorTypeString) - \(self.providedMessage)"
    }

    // 'error' parameter here is a string describing the category or type of the error.
    public init(message: String, error: String, file: StaticString = #file, line: UInt = #line) {
        self.file = file
        self.line = line
        self.providedMessage = message
        self.errorTypeString = error

        let fileName = URL(fileURLWithPath: String(describing: file)).lastPathComponent
        
        // Populate LocalizedError properties
        // This self.errorDescription will be used by error.localizedDescription
        self.errorDescription = "\(self.errorTypeString): \(self.providedMessage) (at \(fileName):\(line))"
        
        self.failureReason = "An issue occurred related to '\(self.errorTypeString)'."
    }
}

// Your ConfigurationError.setup class remains the same:
// open class ConfigurationError {
//     public final class setup: BaseError {
//         public init(message: String, file: StaticString = #file, line: UInt = #line) {
//             super.init(message: message, error: "Configuration error", file: file, line: line)
//         }
//     }
// }
