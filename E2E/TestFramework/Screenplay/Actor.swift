import Foundation
import XCTest

public class Actor {
    public let uuid = UUID().uuidString
    public var name: String
    private var context: [String: Any] = [:]
    private var abilities: [String : any Ability] = [:]
    private var isInitialized: Bool = false
    
    public init(_ name: String) {
        self.name = name
    }
    
    public func tearDown() async throws {
        for ability in abilities.values {
            try await ability.tearDown()
        }
        context.removeAll()
        isInitialized = false
    }
    
    public func whoCanUse<T : Ability>(_ ability: T) -> Actor {
        abilities[String(describing: T.self)] = ability
        ability.setActor(self)
        return self
    }
    
    private func getAbility<T: Ability>(_ ability: T.Type) async throws -> T {
        if !abilities.contains(where: { $0.key == String(describing: ability.self) }) {
            throw ActorError.CantUseAbility("Actor [\(name)] don't have the ability to use [\(ability.self)]")
        }
        
        let ability = self.abilities[String(describing: ability.self)]! as! T
        if (!ability.isInitialized()) {
            try await ability.initialize()
        }
        return ability
    }
    
    public func using<T : Ability>(ability: T.Type,
                                   action: String // = "executes an action"
    ) async throws -> T {
        let ability = try await getAbility(ability)
        return try await execute("\(name) \(action) using \(ability.abilityName)") {
            return ability
        }
    }
    
    public func waitUsingAbility<T: Ability>(ability: T.Type,
                                             action: String, // = "an expectation is met",
                                             callback: (_ ability: T) async throws -> Bool
    ) async throws {
        let ability = try await getAbility(ability)
        return try await execute("\(name) waits until \(action) using \(ability.abilityName)") {
            return try await Wait.until {
                try await callback(ability)
            }
        }
    }
    
    public func remember(key: String, value: Any) async throws {
        return try await execute("\(name) remembers [\(key)]") {
            context[key] = value
        }
    }
    
    public func recall<T>(key: String) async throws -> T {
        return try await execute("\(name) recalls [\(key)]") {
            if (context[key] == nil) {
                throw ActorError.CantFindNote("\(name) don't have any note named [\(key)]")
            }
            return context[key] as! T
        }
    }
    
    private func execute<T>(_ message: String, _ closure: () async throws -> T) async throws -> T {
        let actionOutcome = ActionOutcome()
        actionOutcome.action = message
        do {
            let result = try await closure()
            actionOutcome.executed = true
            try await TestConfiguration.shared().report(.ACTION, actionOutcome)
            return result
        } catch {
            actionOutcome.error = error
            try await TestConfiguration.shared().report(.ACTION, actionOutcome)
            throw error
        }
    }
    
    private func execute<T>(_ message: String, _ closure: () throws -> T) async throws -> T {
        let actionOutcome = ActionOutcome()
        actionOutcome.action = message
        do {
            let result = try closure()
            actionOutcome.executed = true
            try await TestConfiguration.shared().report(.ACTION, actionOutcome)
            return result
        } catch {
            actionOutcome.error = error
            try await TestConfiguration.shared().report(.ACTION, actionOutcome)
            throw error
        }
    }
    
    /// Here we could add attempsTo where actor can run actions, wait, etc
}

enum ActorError : Error {
    case CantUseAbility(_ message: String)
    case CantFindNote(_ message: String)
}
