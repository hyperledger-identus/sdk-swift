import Foundation
import XCTest
import SwiftHamcrest

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
            throw ActorError.cantUseAbility("Actor [\(name)] don't have the ability to use [\(ability.self)]")
        }
        
        let ability = self.abilities[String(describing: ability.self)]! as! T
        if (!ability.isInitialized()) {
            try await ability.initialize()
        }
        return ability
    }
    
    private func getInstance() -> TestConfiguration {
        return TestConfiguration.shared()
    }
    
    private func using<T : Ability>(
        ability: T.Type,
        action: String,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws -> T {
        let ability = try await getAbility(ability)
        return try await getInstance().executeAction("\(name) \(action) using \(ability.abilityName)", file, line) {
            return ability
        }
    }
    
    public func waitUsingAbility<T: Ability>(
        ability: T.Type,
        action: String,
        callback: (_ ability: T) async throws -> Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let ability = try await getAbility(ability)
        return try await getInstance().executeAction("\(name) waits until \(action) using \(ability.abilityName)", file, line) {
            return try await Wait.until {
                try await callback(ability)
            }
        }
    }
    
    public func remember(key: String, value: Any, file: StaticString = #file, line: UInt = #line) async throws {
        return try await getInstance().executeAction("\(name) remembers [\(key)]", file, line) {
            context[key] = value
        }
    }
    
    public func recall<T>(key: String, file: StaticString = #file, line: UInt = #line) async throws -> T {
        return try await getInstance().executeAction("\(name) recalls [\(key)]",file,line) {
            if (context[key] == nil) {
                throw ActorError.cantFindNote("\(name) don't have any note named [\(key)]")
            }
            return context[key] as! T
        }
    }
    
    public func perform<SelectedAbility: Ability, OperationResult>(
        withAbility abilityType: SelectedAbility.Type,
        description: String,
        operation: (_ ability: SelectedAbility) async throws -> OperationResult,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws -> OperationResult {
        let ability = try await getAbility(abilityType)
        let fullActionMessage = "\(name) \(description) using \(ability.abilityName)"
        return try await getInstance().executeAction(fullActionMessage, file, line) {
            try await operation(ability)
        }
    }
}
