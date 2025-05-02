import Foundation
import XCTest

class Utils {
    static func generateNonce(length: Int) -> String {
        var result: String = ""
        
        while (result.count < length) {
            var randomByte: UInt8 = 0
            _ = SecRandomCopyBytes(kSecRandomDefault, 1, &randomByte)
            if (randomByte >= 250) {
                continue
            }
            let randomDigit = randomByte % 10
            result += String(randomDigit)
        }
        return result
    }
}

