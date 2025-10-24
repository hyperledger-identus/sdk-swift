import Foundation

@resultBuilder
public struct CredentialClaimsBuilder {
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

    public static func buildFinalResult(_ components: PartialResult) -> ObjectClaim {
        ObjectClaim(root: true, claims: components.map(\.value))
    }
}
