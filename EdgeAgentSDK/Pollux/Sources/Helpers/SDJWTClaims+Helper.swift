import Core
import Domain
import Foundation
import SwiftyJSON
import eudi_lib_sdjwt_swift

extension ClaimElement {
    func toSdJwtFlat() throws -> FlatDisclosedClaim {
        let encoded = try JSONEncoder.normalized.encode(self)
        let json = try JSON(data: encoded)[key]
        guard let flatClaim = FlatDisclosedClaim(key, json) else {
            throw UnknownError.somethingWentWrongError(customMessage: "Could not create SDJWT from claims")
        }
        return flatClaim
    }

    func toSdJwtClaim() throws -> SdElement {
        switch element {
        case .codable(let codable):
            if disclosable {
                guard let flatClaim = FlatDisclosedClaim(key, codable) else {
                    throw UnknownError.somethingWentWrongError(customMessage: "Could not create SDJWT from claims")
                }
                return flatClaim.value
            } else {
                guard let plainClaim = PlainClaim(key, codable) else {
                    throw UnknownError.somethingWentWrongError(customMessage: "Could not create SDJWT from claims")
                }
                return plainClaim.value
            }
        case .element(let claimElement):
            return try claimElement.toSdJwtClaim()
        case .array(let array):
            if disclosable {
                return try toSdJwtFlat().value
            } else {
                let elements = try array.map { try $0.toSdJwtClaim() }
                return ArrayClaim(key, array: elements)!.value
            }
        case .object(let array):
            if disclosable {
                return try toSdJwtFlat().value
            } else {
                let dictionary = try Dictionary(uniqueKeysWithValues: array.map { try ($0.key, $0.toSdJwtClaim()) })
                return ObjectClaim(key, value: .object(dictionary))!.value
            }
        }
    }
}

extension InputClaim {
    func toSdJwtClaim() throws -> SdElement {
        return try value.toSdJwtClaim()
    }
}

struct SDJWTClaimSerializer: ClaimRepresentable {
    var key: String
    var value: SdElement

    init(input: InputClaim) throws {
        self.key = input.value.key
        self.value = try input.value.toSdJwtClaim()
    }
}
