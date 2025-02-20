import Foundation

public protocol Ability {
    var uuid: String {get}
    var abilityName: String {get}
    var actor: Actor {get}

    init()
    func isInitialized() -> Bool

    /// initialization hook, used to create the object instance for ability
    func initialize() async throws
    func setActor(_ actor: Actor)
    
    /// teardown hook
    func tearDown() async throws
}
