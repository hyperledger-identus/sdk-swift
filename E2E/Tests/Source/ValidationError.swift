import Foundation
import XCTest

enum ValidationError: Error, LocalizedError {
    case error(message: String)
    case http(message: String)
    
    var errorDescription: String? {
        switch self {
        case .error(let message):
            return NSLocalizedString(message, comment: "General validation error")
        case .http(let message):
            return NSLocalizedString(message, comment: "HTTP validation error")
        }
    }
}
