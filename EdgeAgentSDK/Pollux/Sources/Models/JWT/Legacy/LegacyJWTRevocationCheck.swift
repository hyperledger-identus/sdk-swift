import Domain
import Foundation
import Gzip
import JSONWebSignature

struct LegacyJWTRevocationCheck {
    let credential: LegacyJWTCredential

    init(credential: LegacyJWTCredential) {
        self.credential = credential
    }

    func checkIsRevoked() async throws -> Bool {
        guard let status = credential.jwtVerifiableCredential.verifiableCredential.credentialStatus else {
            return false
        }

        guard status.type == "StatusList2021Entry" else {
            throw UnknownError.somethingWentWrongError(customMessage: nil, underlyingErrors: nil)
        }

        let listData = try await DownloadDataWithResolver()
            .downloadFromEndpoint(urlOrDID: status.statusListCredential)
        let statusList = try JSONDecoder.didComm().decode(JWTRevocationStatusListCredential.self, from: listData)
        let encodedList = statusList.credentialSubject.encodedList
        let index = status.statusListIndex
        return try verifyRevocationOnEncodedList(Data(fromBase64URL: encodedList)!, index: index)
    }

    func verifyRevocationOnEncodedList(_ list: Data, index: Int) throws -> Bool {
        let encodedListData = try list.gunzipped()
        let bitList = encodedListData.flatMap { $0.toBits() }
        guard index < bitList.count else {
            throw UnknownError.somethingWentWrongError(customMessage: "Revocation index out of bounds", underlyingErrors: nil)
        }
        return bitList[index]
    }
}

fileprivate struct DownloadDataWithResolver: Downloader {

    public func downloadFromEndpoint(urlOrDID: String) async throws -> Data {
        let url: URL

        if let validUrl = URL(string: urlOrDID.replacingOccurrences(of: "host.docker.internal", with: "localhost")) {
            url = validUrl
        } else {
            throw CommonError.invalidURLError(url: urlOrDID)
        }

        let (data, urlResponse) = try await URLSession.shared.data(from: url)

        guard
            let code = (urlResponse as? HTTPURLResponse)?.statusCode,
            200...299 ~= code
        else {
            throw CommonError.httpError(
                code: (urlResponse as? HTTPURLResponse)?.statusCode ?? 500,
                message: String(data: data, encoding: .utf8) ?? ""
            )
        }

        return data
    }
}

