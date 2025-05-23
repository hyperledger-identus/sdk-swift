import Foundation
import XCTest
import CryptoKit

// MARK: - Allure Data Model Structs (for JSON serialization)

public enum AllureStatus: String, Codable {
    case passed
    case failed
    case broken
    case skipped
    case unknown
}

public enum AllureStage: String, Codable {
    case scheduled
    case running
    case finished
    case pending
    case interrupted
}

public struct AllureLabel: Codable {
    public let name: String
    public let value: String
}

public struct AllureLink: Codable {
    public let name: String?
    public let url: String
    public let type: String?
}

public struct AllureParameter: Codable {
    public let name: String
    public let value: String
    // public var mode: String? // e.g., "masked", "hidden" (optional)
    // public var excluded: Bool? // (optional)
}

public struct AllureStatusDetails: Codable {
    public var known: Bool? = false
    public var muted: Bool? = false
    public var flaky: Bool? = false
    public var message: String?
    public var trace: String?
}

public struct AllureAttachment: Codable {
    public let name: String
    public let source: String
    public let type: String
}

public struct AllureStepResult: Codable {
    public var uuid: String = UUID().uuidString

    public var name: String
    public var status: AllureStatus?
    public var statusDetails: AllureStatusDetails?
    public var stage: AllureStage? = .finished // Most steps are reported once finished
    public var description: String?
    public var descriptionHtml: String?
    public var steps: [AllureStepResult] = [] // For nested steps (from ActionOutcome)
    public var attachments: [AllureAttachment] = []
    public var parameters: [AllureParameter] = []
    public var start: Int64?
    public var stop: Int64?
}

public struct AllureTestResult: Codable {
    /// identifiers
    public let uuid: String
    public var historyId: String?
    public var testCaseId: String?
    /// metadata
    public var name: String?
    public var fullName: String?
    public var description: String?
    public var descriptionHtml: String?
    public var links: [AllureLink] = []
    public var labels: [AllureLabel] = []
    public var parameters: [AllureParameter] = [] // Scenario-level parameters (e.g., from examples table)
    public var attachments: [AllureAttachment] = []
    /// execution
    public var status: AllureStatus?
    public var statusDetails: AllureStatusDetails?
    public var stage: AllureStage? = .finished
    public var start: Int64?
    public var stop: Int64?
    public var steps: [AllureStepResult] = []
}

public struct AllureTestResultContainer: Codable { // Represents a Feature
    public let uuid: String // Unique ID for this container
    public var start: Int64?
    public var stop: Int64?
    public var children: [String] = [] // UUIDs of AllureTestResult (scenario) objects
    public var befores: [AllureFixtureResult] = [] // For setup fixtures
    public var afters: [AllureFixtureResult] = []  // For teardown fixtures
}

public struct AllureFixtureResult: Codable { // For feature-level setup/teardown issues
    public var name: String?
    public var status: AllureStatus?
    public var statusDetails: AllureStatusDetails?
    public var stage: AllureStage? = .finished
    public var description: String?
    public var descriptionHtml: String?
    public var steps: [AllureStepResult] = [] // Fixtures can also have steps
    public var attachments: [AllureAttachment] = []
    public var parameters: [AllureParameter] = []
    public var start: Int64?
    public var stop: Int64?
}


// MARK: - Allure Reporter Implementation

public class AllureReporter: Reporter {
    /// helpers
    private let allureResultsPath: URL
    private let fileManager: FileManager
    private let jsonEncoder: JSONEncoder

    /// state
    private var currentAllureFeatureContainer: AllureTestResultContainer?
    private var currentAllureTestCase: AllureTestResult?
    private var allureStepStack: [AllureStepResult] = []

    public required init() {
        self.fileManager = FileManager.default

        let targetDir: URL
        if let configProvider = TestConfiguration.shared() as? TestConfiguration {
            targetDir = configProvider.targetDirectory()
        } else {
            print("AllureReporter: CRITICAL - Could not determine targetDirectory from TestConfiguration.shared(). Defaulting to current directory for allure-results. THIS IS LIKELY WRONG.")
            targetDir = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        }
        self.allureResultsPath = targetDir.appendingPathComponent("allure-results")
        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.outputFormatting = .prettyPrinted

        do {
            if !fileManager.fileExists(atPath: allureResultsPath.path) {
                try fileManager.createDirectory(at: allureResultsPath,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
            }
            print("AllureReporter: Results directory initialized at: \(allureResultsPath.path)")
        } catch {
            fatalError("AllureReporter: Could not create Allure results directory at '\(allureResultsPath.path)': \(error)")
        }
    }
    
    private func md5Hash(from string: String) -> String {
        guard let data = string.data(using: .utf8) else {
            // Fallback if string can't be UTF-8 encoded, though unlikely for typical identifiers
            return UUID().uuidString // Or some other default
        }
        if #available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *) {
            let digest = Insecure.MD5.hash(data: data)
            return digest.map { String(format: "%02hhx", $0) }.joined()
        } else {
            print("AllureReporter: MD5 not available on this OS version. Using UUID substring for hash.")
            return String(UUID().uuidString.prefix(32))
        }
    }
    
    private func getCurrentPid() -> String {
        let pid = ProcessInfo.processInfo.processIdentifier
        return "pid-\(pid)"
    }
    
    private func generatePackageName(fromFeatureType featureType: Feature.Type) -> String {
        var className = String(describing: featureType)
        if let dotIndex = className.lastIndex(of: ".") {
            className = String(className.suffix(from: className.index(after: dotIndex)))
        }
        var processedName = className
        if processedName.hasSuffix("Feature") {
            processedName = String(processedName.dropLast("Feature".count))
        }
        return "features.\(processedName.lowercased()).feature"
    }

    private func millisecondsSince1970(from date: Date?) -> Int64? {
        guard let date = date else { return nil }
        return Int64(date.timeIntervalSince1970 * 1000)
    }

    private func mapFrameworkStatusToAllureStatus(_ status: TestStatus) -> AllureStatus { // Using your TestStatus
        switch status {
        case .passed: return .passed
        case .failed: return .failed
        case .broken: return .broken
        case .skipped: return .skipped
        case .pending: return .skipped // Allure convention: pending often maps to skipped
        }
    }

    private func allureStatusDetails(from error: Error?) -> AllureStatusDetails? {
        guard let err = error else { return nil }
        
        var message: String
        if let localizedError = err as? LocalizedError, let errDescription = localizedError.errorDescription {
            message = errDescription
        } else {
            message = err.localizedDescription
        }
        if message.isEmpty {
            message = String(describing: err)
        }
        let trace: String = "\(err)"
        return AllureStatusDetails(message: message, trace: trace)
    }
    
    private func ensureResultsDirectoryExists() throws {
        if !fileManager.fileExists(atPath: allureResultsPath.path) {
            print("AllureReporter: Results directory \(allureResultsPath.path) not found before write. Attempting to create.")
            try fileManager.createDirectory(at: allureResultsPath,
                                            withIntermediateDirectories: true,
                                            attributes: nil)
        }
    }
    
    private func writeJSON<T: Encodable>(_ data: T, fileName: String) {
        do {
            try ensureResultsDirectoryExists()
            let filePath = allureResultsPath.appendingPathComponent(fileName)
            let jsonData = try jsonEncoder.encode(data)
            try jsonData.write(to: filePath)
        } catch {
            // Provide more context in the error print if possible
            print("AllureReporter: Error writing Allure JSON for '\(fileName)' to '\(allureResultsPath.appendingPathComponent(fileName).path)': \(error). Underlying POSIX error (if any): \(String(describing: (error as NSError).userInfo[NSUnderlyingErrorKey]))")
        }
    }

    // MARK: - Reporter Protocol Implementation

    public func beforeFeature(_ feature: Feature) async throws {
        let containerUUID = UUID().uuidString
        
        self.currentAllureFeatureContainer = AllureTestResultContainer(
            uuid: containerUUID,
        )
    }

    public func beforeScenario(_ scenario: Scenario) async throws {
        let testCaseUUID = UUID().uuidString
        let scenarioUniqueName = "\(scenario.feature!.name)#\(scenario.name)"
        let calculatedTestCaseId = md5Hash(from: scenarioUniqueName)

        var parameterString = ""
        if let params = scenario.parameters, !params.isEmpty {
            let sortedParams = params.sorted { $0.key < $1.key }
            parameterString = sortedParams.map { "\($0.key)=\($0.value)" }.joined(separator: ";")
        }
        let parameterHash = md5Hash(from: parameterString)
        let calculatedHistoryId = "\(calculatedTestCaseId):\(parameterHash)"
        
        var initialStatus: AllureStatus? = nil
        var initialStage: AllureStage = .running
        if scenario.disabled {
            initialStatus = .skipped
            initialStage = .finished
        }

        self.currentAllureTestCase = AllureTestResult(
            uuid: testCaseUUID,
            historyId: calculatedHistoryId,
            testCaseId: calculatedTestCaseId,
            name: scenario.name,
            fullName: scenarioUniqueName,
            description: scenario.feature?.description(),
            labels: [
                AllureLabel(name: "host", value: ProcessInfo.processInfo.hostName),
                AllureLabel(name: "thread", value: getCurrentPid()),
                AllureLabel(name: "package", value: generatePackageName(fromFeatureType: type(of: scenario.feature!))),
                AllureLabel(name: "language", value: "swift"),
                AllureLabel(name: "framework", value: "identus-e2e-framework"),
                AllureLabel(name: "feature", value: scenario.feature!.title()),
                //AllureLabel(name: "suite", value: "suite"), // FIXME: property? config?
                //AllureLabel(name: "epic", value: "suite"), // FIXME: property? config?
                //AllureLabel(name: "story", value: scenario.name)
            ],
            status: initialStatus,
            stage: initialStage
        )
        allureStepStack.removeAll()
    }

    public func beforeStep(_ step: ConcreteStep) async throws {
        guard self.currentAllureTestCase != nil else {
            print("AllureReporter: Warning - beforeStep called without an active scenario.")
            return
        }

        let allureStep = AllureStepResult(
            name: "\(step.context) \(step.action)",
            stage: .running,
        )
        
        if var parentStep = allureStepStack.last {
            parentStep.steps.append(allureStep)
            allureStepStack[allureStepStack.count - 1] = parentStep
        } else {
            self.currentAllureTestCase?.steps.append(allureStep)
        }
        allureStepStack.append(allureStep)
    }

    public func action(_ actionOutcome: ActionOutcome) async throws {
        var parentAllureStep = allureStepStack.removeLast()
        let subStep = AllureStepResult(
            name: actionOutcome.action,
            status: mapFrameworkStatusToAllureStatus(actionOutcome.status),
            statusDetails: allureStatusDetails(from: actionOutcome.error),
            stage: .finished,
            start: millisecondsSince1970(from: actionOutcome.startTime),
            stop: millisecondsSince1970(from: actionOutcome.endTime)
        )
        parentAllureStep.steps.append(subStep)
        allureStepStack.append(parentAllureStep)
    }

    public func afterStep(_ stepOutcome: StepOutcome) async throws {
        guard var completedAllureStep = allureStepStack.popLast() else {
            print("AllureReporter: Warning - afterStep called with no matching Allure step on stack. Step: \(stepOutcome.step.context) \(stepOutcome.step.action)")
            return
        }

        completedAllureStep.status = mapFrameworkStatusToAllureStatus(stepOutcome.status)
        completedAllureStep.statusDetails = allureStatusDetails(from: stepOutcome.error)
        completedAllureStep.stage = .finished
        completedAllureStep.start = millisecondsSince1970(from: stepOutcome.startTime)
        completedAllureStep.stop = millisecondsSince1970(from: stepOutcome.endTime)
        
        if var parentStep = allureStepStack.last {
            if let index = parentStep.steps.firstIndex(where: { $0.uuid == completedAllureStep.uuid }) {
                parentStep.steps[index] = completedAllureStep
                allureStepStack[allureStepStack.count - 1] = parentStep
            } else {
                 print("AllureReporter: Warning - Could not find step \(completedAllureStep.name) in parent step \(parentStep.name) to update.")
            }
        } else if self.currentAllureTestCase != nil {
            if let index = self.currentAllureTestCase!.steps.firstIndex(where: { $0.uuid == completedAllureStep.uuid }) {
                self.currentAllureTestCase!.steps[index] = completedAllureStep
            } else {
                print("AllureReporter: Warning - Could not find step \(completedAllureStep.name) in current test case to update.")
            }
        }
    }

    public func afterScenario(_ scenarioOutcome: ScenarioOutcome) async throws {
        guard var testCase = self.currentAllureTestCase else {
            print("AllureReporter: Warning - afterScenario called with no active Allure test case. Scenario: \(scenarioOutcome.scenario.name)")
            return
        }

        testCase.status = mapFrameworkStatusToAllureStatus(scenarioOutcome.status)
        let relevantError = scenarioOutcome.error ?? scenarioOutcome.failedStep?.error
        testCase.statusDetails = allureStatusDetails(from: relevantError)
        testCase.stage = .finished
        testCase.start = millisecondsSince1970(from: scenarioOutcome.startTime)
        testCase.stop = millisecondsSince1970(from: scenarioOutcome.endTime)
        
        // If the scenario was disabled and not caught by beforeScenario (e.g. if status was updated later)
        if scenarioOutcome.scenario.disabled && testCase.status != .skipped {
            testCase.status = .skipped
            if testCase.statusDetails == nil {
                testCase.statusDetails = AllureStatusDetails(message: "Scenario was marked as disabled.")
            }
        }
        
        if self.currentAllureFeatureContainer != nil {
            self.currentAllureFeatureContainer!.children.append(testCase.uuid)
        }

        writeJSON(testCase, fileName: "\(testCase.uuid)-result.json")

        self.currentAllureTestCase = nil
        if !allureStepStack.isEmpty {
             print("AllureReporter: Warning - Step stack not empty after scenario \(scenarioOutcome.scenario.name). This may indicate mismatched beforeStep/afterStep calls. Clearing stack.")
             allureStepStack.removeAll()
        }
    }

    public func afterFeature(_ featureOutcome: FeatureOutcome) async throws {
        var container = self.currentAllureFeatureContainer!
        container.start = millisecondsSince1970(from: featureOutcome.startTime)
        container.stop = millisecondsSince1970(from: featureOutcome.endTime)
        if (featureOutcome.status == .broken || featureOutcome.status == .failed),
           let featureErr = featureOutcome.error { // From your FeatureOutcome model
            let fixtureName = "Feature Level Issue: \(featureOutcome.feature.title())"
            let problemFixture = AllureFixtureResult(
                name: fixtureName,
                status: mapFrameworkStatusToAllureStatus(featureOutcome.status),
                statusDetails: allureStatusDetails(from: featureErr),
                stage: .finished,
                start: container.start,
                stop: container.stop
            )
            container.befores.append(problemFixture)
        }
        writeJSON(container, fileName: "\(container.uuid)-container.json")
        self.currentAllureFeatureContainer = nil
    }

    public func afterFeatures(_ featuresOutcome: [FeatureOutcome]) async throws {
//        writeEnvironmentProperties() // Using your TestConfiguration.environment
        print("AllureReporter: All features processed. Allure JSON generation finished. Results in: \(allureResultsPath.path)")
    }

    private func writeEnvironmentProperties() {
        let environmentDict = TestConfiguration.shared().environment
        guard !environmentDict.isEmpty else {
            print("AllureReporter: No environment properties to write (environment dictionary is empty).")
            return
        }
        
        var propertiesContent = ""
        for (key, value) in environmentDict.sorted(by: { $0.key < $1.key }) {
            let escapedKey = key
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: " ", with: "\\ ")
                .replacingOccurrences(of: "=", with: "\\=")
                .replacingOccurrences(of: ":", with: "\\:")
            
            let escapedValue = value
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\r", with: "\\r")

            propertiesContent += "\(escapedKey)=\(escapedValue)\n"
        }
        
        if !propertiesContent.isEmpty {
            let filePath = allureResultsPath.appendingPathComponent("environment.properties")
            do {
                try propertiesContent.write(to: filePath, atomically: true, encoding: .utf8)
            } catch {
                print("AllureReporter: Error writing environment.properties: \(error)")
            }
        }
    }
}
