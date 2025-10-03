import Core
import Foundation

/// `CredentialType` is an enumeration that defines the types of credentials supported in the system.
public enum CredentialType {
    /// Represents a credential in JWT (JSON Web Token) format.
    case jwt

    /// Represents a credential in AnonCred (Anonymous Credentials) format.
    case anoncred

    /// Represents a credential in SDJWT (Selective Disclosure JSON Web Token) format.
    case sdjwt
}

/// `Claim` represents a claim in a credential. Claims are the attributes associated with the subject of a credential.
public struct Claim: Equatable {
    /// `ClaimType` represents the type of value a `Claim` can hold. This can be a string, boolean, date, data, or number.
    public indirect enum ClaimType: Comparable {
        case string(String)
        case bool(Bool)
        case date(Date)
        case data(Data)
        case number(Double)
        case object([Claim])
        case array([ClaimType])

        /// Provides comparison between two `ClaimType` instances based on their inherent values.
        /// - Note: This comparison is only valid for `string`, `date`, and `number` claim types. For other types, it will always return `false`.
        public static func < (lhs: Claim.ClaimType, rhs: Claim.ClaimType) -> Bool {
            switch (lhs, rhs) {
            case let (.string(str1), .string(str2)):
                return str1 < str2
            case let (.date(date1), .date(date2)):
                return date1 < date2
            case let (.number(number1), .number(number2)):
                return number1 < number2
            default:
                return false
            }
        }

        public static func == (lhs: Claim.ClaimType, rhs: Claim.ClaimType) -> Bool {
            switch (lhs, rhs) {
            case let (.string(str1), .string(str2)):
                return str1 == str2
            case let (.bool(bool1), .bool(bool2)):
                return bool1 == bool2
            case let (.date(date1), .date(date2)):
                return date1 == date2
            case let (.data(data1), .data(data2)):
                return data1 == data2
            case let (.number(number1), .number(number2)):
                return number1 == number2
            case let (.object(claims1), .object(claims2)):
                return claims1 == claims2
            case let (.array(claims1), .array(claims2)):
                return claims1 == claims2
            default:
                return false
            }
        }
    }
    
    /// The key of the claim.
    public let key: String
    /// The value of the claim, represented as a `ClaimType`.
    public let value: ClaimType

    /// Initializes a new `Claim` with the provided key and value.
    /// - Parameters:
    ///   - key: The key of the claim.
    ///   - value: The value of the claim, represented as a `ClaimType`.
    public init(key: String, value: ClaimType) {
        self.key = key
        self.value = value
    }
}

/// `Credential` is a protocol that defines the fundamental attributes of a credential.
public protocol Credential {
    /// The identifier of the credential.
    var id: String { get }
    /// The issuer of the credential.
    var issuer: String { get }
    /// The subject of the credential.
    var subject: String? { get }
    /// The claims included in the credential.
    var claims: [Claim] { get }
    /// Additional properties associated with the credential.
    var properties: [String: Any] { get }
    /// The type of the credential Ex: JWT, Anoncred, W3C
    var credentialType: String { get }
}

public extension Credential {
    /// A Boolean value indicating whether the credential is Codable.
    var isCodable: Bool { self is Codable }
    
    /// Returns the Codable representation of the credential.
    var codable: Codable? { self as? Codable }
}

public protocol NewCredential {
    var id: String { get }
    var issuer: String { get }
    var subjects: [String] { get }
    var validFrom: Date? { get }
    var validTo: Date? { get }
    var properties: [String: Any] { get }
    var credentialType: String { get }
    func getSubjectClaims(for subject: String) throws -> [Claim]
}
