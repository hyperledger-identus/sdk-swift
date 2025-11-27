import Domain
import Foundation

extension JWTCredential: ExportableCredential {
    public var exporting: Data {
        (try? jwtString.tryToData()) ?? Data()
    }

    public var restorationType: String { "jwt" }
}
