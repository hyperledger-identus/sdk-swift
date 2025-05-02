import Foundation

public class FeatureOutcome {
    let feature: Feature
    var scenarios: [ScenarioOutcome] = []
    var failedScenarios: [ScenarioOutcome] = []
    
    init(_ feature: Feature) {
        self.feature = feature
    }
}
