import Foundation
import SwiftHamcrest

func reportResult(_ possibleResult: String?, message: String? = nil, file: StaticString = #file, line: UInt = #line)
    -> String {
    if let possibleResult = possibleResult {
        let result: String
        if let message = message {
            result = "\(message) - \(possibleResult)"
        } else {
            result = possibleResult
        }
        HamcrestReportFunction(result, file, line)
        return result
    } else {
        // The return value is just intended for Playgrounds.
        return "✓"
    }
}

func describeExpectedError() -> String {
    return "EXPECTED ERROR"
}

@discardableResult public func assertThrows<T>(_ value: @autoclosure () async throws -> T, file: StaticString = #file, line: UInt = #line) async -> String {
    do {
        _ = try await value()
        return reportResult(describeExpectedError(), file: file, line: line)
    } catch {
        return reportResult(nil, file: file, line: line)
    }
}
