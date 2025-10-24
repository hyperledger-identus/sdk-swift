import Foundation

public struct ObjectClaim: InputClaim {
    let isRoot: Bool
    public var value: ClaimElement
    
    /// A result builder for constructing object claims.
    @resultBuilder
    public struct ObjectClaimBuilder {
        public typealias PartialResult = [any InputClaim]

        public static func buildExpression(_ expression: any InputClaim) -> PartialResult {
            [expression]
        }

        public static func buildExpression(_ expression: PartialResult) -> PartialResult {
            expression
        }

        public static func buildBlock(_ components: PartialResult...) -> PartialResult {
            components.flatMap { $0 }
        }
        
        public static func buildBlock(_ component: PartialResult) -> PartialResult {
            component
        }

        public static func buildOptional(_ component: PartialResult?) -> PartialResult {
            component ?? []
        }

        public static func buildEither(first component: PartialResult) -> PartialResult {
            component
        }

        public static func buildEither(second component: PartialResult) -> PartialResult {
            component
        }
        
        public static func buildEmpty() -> PartialResult {
            []
        }
    }
    
    /// Initializes an `ObjectClaim` with a key and a builder for the object elements.
    /// - Parameters:
    ///   - key: The key for the claim.
    ///   - claims: A closure that returns an array of `Claim` using the result builder.
    public init(key: String, @ObjectClaimBuilder claims: () -> [InputClaim], disclosable: Bool = false) {
        self.isRoot = false
        self.value = .init(key: key, element: .object(claims().map(\.value)), disclosable: disclosable)
    }
    
    init(key: String, claims: [ClaimElement], disclosable: Bool = false) {
        self.isRoot = false
        self.value = .init(key: key, element: .object(claims), disclosable: disclosable)
    }
    
    init(root: Bool, claims: [ClaimElement], disclosable: Bool = false) {
        self.isRoot = root
        self.value = .init(key: "", element: .object(claims), disclosable: disclosable)
    }
}
