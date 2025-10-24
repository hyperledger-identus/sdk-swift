import Foundation

public indirect enum Value {
    case codable(Codable)
    case element(ClaimElement)
    case array([ClaimElement])
    case object([ClaimElement])
}

public protocol InputClaim {
    var value: ClaimElement { get }
}

public struct ClaimElement {
    public let key: String
    public let element: Value
    public let disclosable: Bool

    init(key: String, element: Value, disclosable: Bool) {
        self.key = key
        self.element = element
        self.disclosable = disclosable
    }

    /// Initializes a `ClaimElement` with a codable value.
    /// - Parameters:
    ///   - key: The key for the claim.
    ///   - value: The codable value of the claim.
    public init<C: Codable>(key: String, value: C, disclosable: Bool) {
        self.key = key
        self.element = .codable(value)
        self.disclosable = disclosable
    }
}
