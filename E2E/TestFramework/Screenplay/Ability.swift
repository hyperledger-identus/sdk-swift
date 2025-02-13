import Foundation

public protocol Ability {
    var abilityName: String {get}
    var actor: Actor {get}
    var isInitialized: Bool {get}
    
    init()

    /// initialization hook, used to create the object instance for ability
    func initialize() async throws
    func setActor(_ actor: Actor)
    
    /// teardown hook
    func tearDown() async throws
}
