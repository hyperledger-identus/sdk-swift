import Foundation

class Wait {
    static func until(timeout: Int = 30, callback: () async throws -> Bool, file: StaticString = #file, line: UInt = #line) async throws {
        let startTime = Date()
        while try await !callback() {
            if Date().timeIntervalSince(startTime) >= Double(timeout) {
                throw Assertion.TimeoutError(
                    timeout: timeout,
                    file: file,
                    line: line
                )
            }
            try await Task.sleep(nanoseconds: UInt64(500000000))
        }
    }
}
