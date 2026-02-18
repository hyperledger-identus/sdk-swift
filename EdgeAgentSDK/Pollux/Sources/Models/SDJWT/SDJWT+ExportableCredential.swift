import Domain
import Foundation

extension SDJWTCredential: ExportableCredential {
    public var exporting: Data {
        (try? sdjwtString.tryToData()) ?? Data()
    }

    public var restorationType: String { "sdjwt" }
}
