public extension UInt8 {
    func toBits() -> [Bool] {
        var bits = [Bool](repeating: false, count: 8)
        for i in 0..<8 {
            bits[7 - i] = (self & (1 << i)) != 0
        }
        return bits
    }
}
