public extension Optional {
    func orThrow(_ error: Error) throws -> Wrapped {
        if let value = self { return value }
        throw error
    }
}
