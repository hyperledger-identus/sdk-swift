import Foundation
import XCTest

class TestObserver: NSObject, XCTestObservation {
    func testBundleDidFinish(_ testBundle: Bundle) {
        TestConfiguration.shared().end()
    }
}
