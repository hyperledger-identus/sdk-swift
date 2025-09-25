import Domain
import Foundation

extension AnoncredsCredentialStack: ProvableCredential {
    func presentation(type: String, requestPayload: Data, options: [CredentialOperationsOptions]) throws -> String {
        let requestStr = try requestPayload.tryToString()
        guard
            let linkSecretOption = options.first(where: {
                if case .linkSecret = $0 { return true }
                return false
            }),
            case let CredentialOperationsOptions.linkSecret(_, secret: linkSecret) = linkSecretOption
        else {
            throw PolluxError.missingAndIsRequiredForOperation(type: "LinkSecret")
        }

        if
            let zkpParameters = options.first(where: {
                if case .zkpPresentationParams = $0 { return true }
                return false
            }),
            case let CredentialOperationsOptions.zkpPresentationParams(attributes, predicates) = zkpParameters
        {
            return try AnoncredsPresentation().createPresentation(
                stack: self,
                request: requestStr,
                linkSecret: linkSecret,
                attributes: attributes,
                predicates: predicates
            )
        } else {
            return try AnoncredsPresentation().createPresentation(
                stack: self,
                request: requestStr,
                linkSecret: linkSecret,
                attributes: try computeAttributes(requestJson: requestStr),
                predicates: try computePredicates(requestJson: requestStr)
            )
        }
    }

    func isValidForPresentation(
        type: String,
        requestPayload: Data,
        options: [CredentialOperationsOptions]
    ) throws -> Bool {
        switch type {
        case "anoncreds/proof-request@v1.0":
            return true
        default:
            return false
        }
    }
}

private func computeAttributes(requestJson: String) throws -> [String: Bool] {
    guard
        let json = try JSONSerialization.jsonObject(with: try requestJson.tryData(using: .utf8)) as? [String: Any]
    else {
        throw PolluxError.messageDoesntProvideEnoughInformation
    }
    let requestedAttributes = json["requested_attributes"] as? [String: Any]
    return requestedAttributes?.reduce([:]) { partialResult, row in
        var dic = partialResult
        dic[row.key] = true
        return dic
    } ?? [:]
}

private func computePredicates(requestJson: String) throws -> [String] {
    guard
        let json = try JSONSerialization.jsonObject(with: try requestJson.tryData(using: .utf8)) as? [String: Any]
    else {
        throw PolluxError.messageDoesntProvideEnoughInformation
    }
    let requestedPredicates = json["requested_predicates"] as? [String: Any]
    return requestedPredicates?.map { $0.key } ?? []
}
