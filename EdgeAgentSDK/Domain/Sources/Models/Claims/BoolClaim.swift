import Foundation

public struct BoolClaim: InputClaim {
    public var value: ClaimElement
    
    /// Initializes a `BoolClaim` with a key and a boolean value.
    /// - Parameters:
    ///   - key: The key for the claim.
    ///   - value: The boolean value for the claim.
    public init(key: String, value: Bool, disclosable: Bool = false) {
        self.value = ClaimElement(key: key, element: .codable(value), disclosable: disclosable)
    }
}
