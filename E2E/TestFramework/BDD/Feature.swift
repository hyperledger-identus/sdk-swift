import Foundation
import XCTest
import SwiftHamcrest

open class Feature: XCTestCase {
    let id: String = UUID().uuidString
    open var currentScenario: Scenario? = nil

    open func title() -> String {
        fatalError("Set feature title")
    }

    open func description() -> String {
        return ""
    }
    
    /// our lifecycle starts after xctest is ending
    public override func tearDown() async throws {
        var errorFromRun: Error?
        do {
            try await run()
        } catch {
            errorFromRun = error
        }
        self.currentScenario = nil
        var superTeardownError: Error?
        do {
            try await super.tearDown()
        } catch {
            superTeardownError = error
        }

        if let errorToThrow = errorFromRun ?? superTeardownError {
            throw errorToThrow
        }
    }

    public override class func tearDown() {
        if (TestConfiguration.started) {
            let semaphore = DispatchSemaphore(value: 0)
            Task.detached {
                try await TestConfiguration.shared().endCurrentFeature()
                semaphore.signal()
            }
            semaphore.wait()
        }
        super.tearDown()
    }

    func run() async throws {
        let currentTestMethodName = self.name
        if currentScenario == nil {
            let rawMethodName = currentTestMethodName.split(separator: " ").last?.dropLast() ?? "yourTestMethod"
            
            let errorMessage = """
            ‼️ SCENARIO NOT DEFINED in test method: \(currentTestMethodName)
            Each 'func test...()' method within a 'Feature' class must assign a 'Scenario' to 'self.currentScenario'.

            Example:
            func \(rawMethodName)() async throws {
                currentScenario = Scenario("A brief scenario description", file: #file, line: #line)
                    .given("some precondition")
                    .when("some action")
                    .then("some expected outcome")
            }
            """
            throw ConfigurationError.missingScenario(errorMessage)
        }
        if currentScenario!.disabled {
            throw XCTSkip("Scenario '\(currentScenario!.name)' in test method \(currentTestMethodName) is disabled.")
        }
        try await TestConfiguration.setUpInstance()
        
        if let parameterizedScenario = currentScenario as? ParameterizedScenario {
            for scenarioInstance in parameterizedScenario.build() {
                scenarioInstance.feature = self
                try await TestConfiguration.shared().run(self, scenarioInstance)
            }
        } else {
            currentScenario?.feature = self
            try await TestConfiguration.shared().run(self, currentScenario!)
        }
    }
}
