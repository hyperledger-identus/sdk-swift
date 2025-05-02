
import Foundation

@propertyWrapper
struct ParameterParser<T> {
    var wrappedValue: (String) async throws -> T
    
    init(wrappedValue: @escaping (String) async throws  -> T) {
        self.wrappedValue = wrappedValue
        ParserRegistry.addParser(wrappedValue)
    }
}

struct ParserRegistry {
    static var annotatedMethods: [String: (String) async throws -> Any] = [:]
    
    static func getParser<T>(_ name: String) async throws -> (String) async throws -> T {
        return ParserRegistry.annotatedMethods[name] as! (String) async throws -> T
    }
    
    static func addParser<T>(_ callback: @escaping (String) async throws -> T) {
        let type = String(describing: T.self).uppercased()
        ParserRegistry.annotatedMethods[type] = callback
    }
}
