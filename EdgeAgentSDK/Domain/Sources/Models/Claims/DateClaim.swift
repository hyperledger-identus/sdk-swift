import Foundation

public struct DateClaim: InputClaim {
    public var value: ClaimElement

    /// Initializes a `DateClaim` with a key and a date value.
    /// - Parameters:
    ///   - key: The key for the claim.
    ///   - value: The date value for the claim.
    public init(key: String, value: Date, disclosable: Bool = false) {
        self.value = ClaimElement(key: key, element: .codable(value), disclosable: disclosable)
    }
}
