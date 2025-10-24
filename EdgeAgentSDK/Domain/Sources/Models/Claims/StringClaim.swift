import Foundation

public struct StringClaim: InputClaim {
    public var value: ClaimElement
    
    /// Initializes a `StringClaim` with a key and a string value.
    /// - Parameters:
    ///   - key: The key for the claim.
    ///   - value: The string value for the claim.
    public init(key: String, value: String, disclosable: Bool = false) {
        self.value = ClaimElement(key: key, element: .codable(value), disclosable: disclosable)
    }
}
