import Foundation

public struct NumberClaim: InputClaim {
    public var value: ClaimElement
    
    /// Initializes a `NumberClaim` with a key and a numeric value.
    /// - Parameters:
    ///   - key: The key for the claim.
    ///   - value: The numeric value for the claim.
    public init<N: Numeric & Codable>(key: String, value: N, disclosable: Bool = false) {
        self.value = ClaimElement(key: key, element: .codable(value), disclosable: disclosable)
    }
}
