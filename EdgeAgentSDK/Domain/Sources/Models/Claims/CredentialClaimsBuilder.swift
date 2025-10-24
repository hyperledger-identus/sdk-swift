import Foundation

/// A Swift result builder that constructs a collection of credential input claims and
/// produces a final `ObjectClaim` representing a root-level claim object.
///
/// Use `CredentialClaimsBuilder` to create a declarative, DSL-style syntax for assembling
/// credential claims. Within a builder context, you can:
/// - Add individual claims conforming to `InputClaim`.
/// - Combine arrays of claims.
/// - Conditionally include claims using `if`/`else` and `if let`.
/// - Include no claims in empty branches.
/// - Compose multiple claim groups using standard control-flow.
///
/// The builder collects intermediate results as `[any InputClaim]` and, in `buildFinalResult`,
/// transforms them into a single `ObjectClaim` with `root: true`, where each element's
/// `value` is extracted and used as part of the final object.
///
/// Notes:
/// - `buildExpression(_:)` supports both single `InputClaim` values and arrays of them.
/// - `buildBlock` overloads allow composing multiple partial results or passing through a single one.
/// - `buildOptional(_:)` returns an empty collection when the optional branch is `nil`.
/// - `buildEither(first:)` and `buildEither(second:)` support `if`/`else` control-flow.
/// - `buildEmpty()` represents an empty branch, returning an empty collection.
/// - `buildFinalResult(_:)` is where the builder converts the accumulated claims into an `ObjectClaim`.
///
/// Example usage:
/// ```swift
/// let objectClaim: ObjectClaim = buildCredentialClaims {
///     SomeInputClaim(key: "name", value: "Ada")
///     if includeEmail {
///         SomeInputClaim(key: "email", value: "ada@example.com")
///     }
///     if let phone = optionalPhone {
///         SomeInputClaim(key: "phone", value: phone)
///     }
/// }
/// ```
///
/// Requirements:
/// - `InputClaim` must expose a `value` used when producing the final `ObjectClaim`.
/// - `ObjectClaim` must support initialization with `root: Bool` and an array of claim values.
///
/// Intended platform usage:
/// - Designed for Swift on Apple platforms, leveraging `@resultBuilder` to create expressive,
///   type-safe claim construction DSLs for credentials and identity documents.
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
