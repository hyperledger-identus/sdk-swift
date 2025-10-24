import Domain
import Foundation

extension Value {
    func getValue<T>() -> T? {
        switch self {
        case .codable(let value):
            return value as? T
        default:
            return nil
        }
    }

    func getObjectClaims() -> [ClaimElement]? {
        switch self {
        case .object(let values):
            return values
        default:
            return nil
        }
    }

    func getArrayClaims() -> [ClaimElement]? {
        switch self {
        case .array(let values):
            return values
        default:
            return nil
        }
    }
}

extension ObjectClaim {
    var objectClaims: [ClaimElement] {
        switch value.element {
        case .object(let array):
            return array
        default:
            return []
        }
    }

    var issuer: String? {
        guard let issuer = objectClaims.first(where: { $0.key == "iss" || $0.key == "issuer" })?.element else {
            return nil
        }
        switch issuer {
        case .object(let claims):
            return claims.first { $0.key == "id" }?.element.getValue()
        default:
            return issuer.getValue()
        }
    }

    var subjects: [String] {
        var subjects = [String?]()
        subjects.append(objectClaims.first { $0.key == "sub" }?.element.getValue())
        for subject in credentialSubjects {
            switch subject {
            case .object(let claims):
                subjects.append(claims.first { $0.key == "id" }?.element.getValue())
            default:
                break
            }
        }
        return subjects.compactMap { $0 }
    }

    var credentialSubjects: [Value] {
        guard let credentialSubject = objectClaims.first(where: { $0.key == "credentialSubject" })?.element else {
            return []
        }
        switch credentialSubject {
        case .array(let elements):
            return elements.map(\.element)
        case .object:
            return [credentialSubject]
        default:
            return []
        }
    }

    public var id: String? {
        objectClaims.first { $0.key == "id" }?.element.getValue()
    }
}
