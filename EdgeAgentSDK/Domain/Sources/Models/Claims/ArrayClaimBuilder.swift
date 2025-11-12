/// A Swift result builder that simplifies the construction of heterogeneous collections of claims.
///
/// ArrayClaimBuilder supports building arrays of different claim types used in the claims system:
/// - `any InputClaim` (erased protocol type for general claims)
/// - `ArrayElementClaim` (claims that represent elements within an array)
/// - `StringClaim` (claims that operate on string values)
///
/// This builder enables a declarative DSL-like syntax to compose claims with:
/// - Multiple `buildBlock` overloads to handle different claim array types
/// - Support for optional sections via `buildOptional`
/// - Conditional branching via `buildEither(first:)` and `buildEither(second:)`
/// - Flattening of nested arrays via `buildArray`
/// - Expression lifting via `buildExpression` for each supported claim type
///
/// Typical usage:
/// - Use in an API that takes a closure annotated with `@ArrayClaimBuilder`
/// - Compose claims inline using standard control flow constructs (`if`, `if/else`, optionals)
///
/// Notes:
/// - Overloaded `buildBlock` methods allow the same builder to be used in contexts that expect
///   different element types, while keeping type safety.
/// - Each `buildArray` variant flattens nested arrays to a single-level array.
/// - Optional and conditional helpers return empty arrays when absent, which naturally composes
///   into the final result without additional branching.
///
/// Dependencies:
/// - `InputClaim` protocol/type-erased existential used via `any InputClaim`
/// - `ArrayElementClaim` value type used for array element-level claims
/// - `StringClaim` value type used for string-specific claims
///
/// Example (conceptual):
/// @ArrayClaimBuilder
/// func makeClaims() -> [any InputClaim] {
///     StringClaim.equals("hello")
///     if condition {
///         ArrayElementClaim.index(0)
///     }
///     optionalClaim
/// }
///
/// The builder will collect, flatten, and return the correct array type based on the function's return type.
@resultBuilder
public struct ArrayClaimBuilder {
//    public typealias ClaimPartialResult = [any InputClaim]
    public typealias ArrayClaimPartialResult = [ArrayValueClaim]
//    public typealias StringClaimPartialResult = [StringClaim]
    /// Builds an array of `ArrayElementClaim` from the provided components.
    /// - Parameter components: The array element claims to include in the array.
    /// - Returns: An array of `ArrayElementClaim`.
    public static func buildBlock(_ components: ArrayClaimPartialResult...) -> ArrayClaimPartialResult {
        components.flatMap { $0 }
    }

    /// Builds an array of `ArrayElementClaim` from the provided components.
    /// - Parameter components: The array element claims to include in the array.
    /// - Returns: An array of `ArrayElementClaim`.
//    public static func buildBlock(_ components: ClaimPartialResult...) -> ClaimPartialResult {
//        components.flatMap { $0 }
//    }

    /// Builds an array of `StringClaim` from the provided components.
    /// - Parameter components: The string claims to include in the array.
    /// - Returns: An array of `StringClaim`.
//    public static func buildBlock(_ components: StringClaimPartialResult...) -> StringClaimPartialResult {
//        components.flatMap { $0 }
//    }

//    public static func buildPartialBlock(first: ClaimPartialResult) -> ClaimPartialResult {
//        first
//    }
//
//    public static func buildPartialBlock(accumulated: ClaimPartialResult, next: ClaimPartialResult) -> ClaimPartialResult {
//        accumulated + next
//    }
//
//    public static func buildExpression(_ expression: any InputClaim) -> ClaimPartialResult {
//        [expression]
//    }

    public static func buildExpression(_ expression: ArrayValueClaim) -> ArrayClaimPartialResult {
        [expression]
    }

//    public static func buildExpression(_ expression: StringClaim) -> StringClaimPartialResult {
//        [expression]
//    }

//    public static func buildArray(_ components: [ClaimPartialResult]) -> ClaimPartialResult {
//        components.flatMap { $0 }
//    }

    public static func buildArray(_ components: [ArrayClaimPartialResult]) -> ArrayClaimPartialResult {
        components.flatMap { $0 }
    }

//    public static func buildArray(_ components: [StringClaimPartialResult]) -> StringClaimPartialResult {
//        components.flatMap { $0 }
//    }

    /// Adds support for optionals
//    public static func buildOptional(_ component:  ClaimPartialResult?) -> ClaimPartialResult {
//        guard let component else {
//            return []
//        }
//        return component
//    }

    public static func buildOptional(_ component: ArrayClaimPartialResult?) -> ArrayClaimPartialResult {
        guard let component else {
            return []
        }
        return component
    }

    /// Adds support for if statements in build block
//    public static func buildEither(first component: ClaimPartialResult) -> ClaimPartialResult {
//        component
//    }
//
//    public static func buildEither(second component: ClaimPartialResult) -> ClaimPartialResult {
//        component
//    }

    public static func buildEither(first component: ArrayClaimPartialResult) -> ArrayClaimPartialResult {
        component
    }

    public static func buildEither(second component: ArrayClaimPartialResult) -> ArrayClaimPartialResult {
        component
    }

    /// Adds support for optionals
//    public static func buildOptional(_ component:  StringClaimPartialResult?) -> StringClaimPartialResult {
//        guard let component else {
//            return []
//        }
//        return component
//    }


    /// Adds support for if statements in build block
//    public static func buildEither(first component: StringClaimPartialResult) -> StringClaimPartialResult {
//        component
//    }
//
//    public static func buildEither(second component: StringClaimPartialResult) -> StringClaimPartialResult {
//        component
//    }

//    public static func buildFinalResult(_ component: ArrayClaimPartialResult) -> ClaimPartialResult {
//        component.map(\.value)
//    }
//
//    public static func buildFinalResult(_ component: StringClaimPartialResult) -> ClaimPartialResult {
//        component
//    }

    public static func buildFinalResult(_ component: ArrayClaimPartialResult) -> [InputClaim] {
        component.map(\.value)
    }
}
