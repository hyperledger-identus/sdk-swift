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
        try await run()
        self.currentScenario = nil
        try await super.tearDown()
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
        // check if we have the scenario
        if (currentScenario == nil) {
            throw XCTSkip("""
            To run the feature you have to setup the scenario for each test case.
            Usage:
            func testMyScenario() async throws {
                scenario = Scenario("description")
                    .given // ...
            }
            """)
        }
        
        if (currentScenario!.disabled) {
            throw XCTSkip("Scenario [\(currentScenario!.title)] is disabled")
        }
        
        try await TestConfiguration.setUpInstance()
        
        if (currentScenario! is ParameterizedScenario) {
            let parameterizedScenario = currentScenario! as! ParameterizedScenario
            for scenario in parameterizedScenario.build() {
                try await TestConfiguration.shared().run(self, scenario)
            }
        } else {
            try await TestConfiguration.shared().run(self, currentScenario!)
        }
    }
}
