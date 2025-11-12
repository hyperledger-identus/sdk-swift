/// A Swift result builder that constructs an array of `InputClaim` instances for building object claims.
///
/// Use `ObjectClaimBuilder` to declaratively compose multiple `InputClaim` values
/// into a single `[any InputClaim]` collection. This builder supports standard
/// result builder features such as conditionals, optionals, and block composition,
/// enabling expressive and readable configuration of object claims.
///
/// Behavior:
/// - Aggregates expressions of type `any InputClaim` into a `[any InputClaim]`.
/// - Flattens nested partial results to produce a single, linear collection.
/// - Supports optional blocks; empty arrays are produced when `nil`.
/// - Supports conditional branches (`if/else` and `switch` via `buildEither`).
/// - Produces an empty array when no components are provided.
///
/// Notes:
/// - The `PartialResult` typealias is `[any InputClaim]`.
/// - Each `build*` method corresponds to a standard result builder operation:
///   - `buildExpression(_:)` accepts a single `InputClaim` or an existing partial result.
///   - `buildBlock(_:)` combines one or more partial results, flattening as needed.
///   - `buildOptional(_:)` unwraps optional partial results, defaulting to `[]`.
///   - `buildEither(first:)` and `buildEither(second:)` support branching.
///   - `buildEmpty()` returns an empty collection when no content is provided.
///
/// Intended Use:
/// - Apply `@ObjectClaimBuilder` to function parameters or computed properties
///   that should accept a declarative list of `InputClaim`s.
///
/// Requirements:
/// - Relies on the `InputClaim` protocol existing in the module.
/// - Designed for Apple platforms using Swift result builders.
///
/// Performance:
/// - Uses `flatMap` when combining multiple blocks to avoid nested arrays.
/// - Array concatenation is linear in the number of claims included.
///
/// Thread Safety:
/// - The builder itself is stateless; thread safety depends on the underlying
///   `InputClaim` implementations and how the produced array is used.
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
