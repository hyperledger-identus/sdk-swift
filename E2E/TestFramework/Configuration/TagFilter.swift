import Foundation

struct TagFilter {
    private let expression: String

    /// Initializes the filter with the raw tag expression string from the environment.
    init(from expression: String?) {
        self.expression = expression?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    /// Determines if a scenario with the given tags should be executed based on the expression.
    func shouldRun(scenarioTags: [String]) -> Bool {
        // If there's no expression, run everything.
        if expression.isEmpty {
            return true
        }
        
        let scenarioTagSet = Set(scenarioTags)
        
        // Split by "or" to handle the lowest precedence operator first.
        // If any of these OR clauses are true, the whole expression is true.
        let orClauses = expression.components(separatedBy: " or ")
        
        for orClause in orClauses {
            // Check if this "AND" group is satisfied.
            if evaluateAndClause(clause: orClause, scenarioTags: scenarioTagSet) {
                return true
            }
        }
        
        // If none of the OR clauses were satisfied, the expression is false.
        return false
    }

    /// Evaluates a sub-expression containing only "and" and "not" conditions.
    /// This clause is true only if ALL of its conditions are met.
    private func evaluateAndClause(clause: String, scenarioTags: Set<String>) -> Bool {
        let andConditions = clause.components(separatedBy: " and ")
        
        for condition in andConditions {
            if !evaluateCondition(condition: condition, scenarioTags: scenarioTags) {
                return false // If any condition is false, the whole AND clause is false.
            }
        }
        
        // If all conditions passed, the AND clause is true.
        return true
    }
    
    /// Evaluates a single tag condition (e.g., "@smoke" or "not @wip").
    private func evaluateCondition(condition: String, scenarioTags: Set<String>) -> Bool {
        let trimmedCondition = condition.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedCondition.hasPrefix("not ") {
            let tag = String(trimmedCondition.dropFirst(4))
            return !scenarioTags.contains(tag)
        } else {
            let tag = trimmedCondition
            return scenarioTags.contains(tag)
        }
    }
}
