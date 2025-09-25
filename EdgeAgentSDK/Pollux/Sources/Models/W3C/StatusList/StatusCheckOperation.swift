import Core
import Domain
import Foundation
import Gzip
import JSONWebSignature

struct StatusCheckOperation {
    let statusListEntry: StatusListEntry

    init(statusListEntry: StatusListEntry) {
        self.statusListEntry = statusListEntry
    }

    func checkStatus() async throws -> Bool {
        let listData = try await DownloadDataWithResolver()
            .downloadFromEndpoint(urlOrDID: statusListEntry.statusListCredential)
        let statusList = try JSONDecoder.didComm().decode(StatusListCredential.self, from: listData)
        let encodedList = statusList.credentialSubject.encodedList
        let index = statusListEntry.statusListIndex
        let size = statusListEntry.statusSize
        return try verifyStatusOnEncodedList(
            try Data(
                fromBase64URL: encodedList
            )
            .orThrow(UnknownError.somethingWentWrongError(customMessage: "Invalid base64 encoded string", underlyingErrors: nil)),
            index: index,
            size: size
        )
    }

    func verifyStatusOnEncodedList(
        _ list: Data,
        index: Int,
        size: Int,
        statusEntries: [String]? = nil
    ) throws -> Bool {
        let encodedListData = try list.gunzipped()
        let bitList = encodedListData.flatMap { $0.toBits() }

        guard size == 1 else {
            throw PolluxError.unsupportedCredentialStatusType(message: "Credential Status with statusSize > 1 are not supported yet.")
        }

        return try verifySingleStatus(bitList, index: index)
    }

    func verifySingleStatus(
        _ bitList: [Bool],
        index: Int,
    ) throws -> Bool {
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
