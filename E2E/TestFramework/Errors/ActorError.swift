import Foundation

class ActorError {
    class actionError: BaseError {
        init(message: String, error: Error, file: StaticString, line: UInt) {
            super.init(message: message, error: String(describing: error), file: file, line: line)
        }
    }
    
    class cantUseAbility: BaseError {
        init(_ message: String, file: StaticString = #file, line: UInt = #line) {
            super.init(message: message, error: "Actor cannot use ability", file: file, line: line)
        }
    }
    class cantFindNote: BaseError {
        init(_ message: String, file: StaticString = #file, line: UInt = #line) {
            super.init(message: message, error: "Actor cannot find note", file: file, line: line)
        }
    }
}
