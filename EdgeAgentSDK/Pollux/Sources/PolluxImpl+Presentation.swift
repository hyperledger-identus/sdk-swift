import AnoncredsSwift
import Domain
import Foundation

extension PolluxImpl {
    public func createPresentationRequest(
        type: CredentialType,
        toDID: DID,
        name: String,
        version: String,
        claimFilters: [ClaimFilter]
    ) throws -> Data {
        switch type {
        case .jwt:
            let descriptors = claimFilters
                .map {
                    InputDescriptor(
                        name: $0.name,
                        purpose: $0.purpose,
                        group: nil,
                        constraints: .init(
                            fields: [
                                .init(
                                    optional: !$0.required,
                                    path: $0.paths,
                                    purpose: $0.purpose,
                                    intentToRetain: nil,
                                    name: $0.name,
                                    filter: .init(
                                        type: $0.type,
                                        format: $0.format,
                                        const: $0.const,
                                        pattern: $0.pattern
                                    ),
                                    predicate: nil
                                )
                            ]
                        )
                    )
                }
            let presentationDefinition = PresentationDefinition(
                format: .init(jwt: .init(alg: [.ES256K])),
                inputDescriptors: descriptors
            )

            let container = PresentationExchangeRequest(
                options: .init(domain: UUID().uuidString, challenge: UUID().uuidString),
                presentationDefinition: presentationDefinition
            )
            return try JSONEncoder.didComm().encode(container)

        case .anoncred:
            let requestedFields = claimFilters
                .reduce([String: AnoncredsPresentationRequest.RequestedAttribute](), { partialResult, filter in
                    var dic = partialResult
                    let key = filter.name ?? filter.type
                    guard filter.pattern == nil else {
                        return dic
                    }
                    dic[key] = AnoncredsPresentationRequest.RequestedAttribute(name: key, restrictions: [])
                    return dic
                })

            let requestedPredicates = claimFilters
                .reduce([String: AnoncredsPresentationRequest.RequestedPredicate](), { partialResult, filter in
                    var dic = partialResult
                    guard
                        let pType = filter.pattern,
                        let pValueStr = filter.const,
                        let pValue = Int(pValueStr)
                    else {
                        return dic
                    }
                    let key = filter.name ?? filter.type
                    dic[key] = AnoncredsPresentationRequest.RequestedPredicate(name: key, pType: pType, pValue: pValue)
                    return dic
                })
            
            let anoncredsPresentation = AnoncredsPresentationRequest(
                nonce: try Nonce().getValue(),
                name: name,
                version: version,
                requestedAttributes: requestedFields,
                requestedPredicates: requestedPredicates
            )

            return try JSONEncoder.didComm().encode(anoncredsPresentation)

        case .sdjwt:
            let descriptors = claimFilters
                .map {
                    InputDescriptor(
                        name: $0.name,
                        purpose: $0.purpose,
                        group: nil,
                        constraints: .init(
                            fields: [
                                .init(
                                    optional: !$0.required,
                                    path: $0.paths,
                                    purpose: $0.purpose,
                                    intentToRetain: nil,
                                    name: $0.name,
                                    filter: .init(
                                        type: $0.type,
                                        format: $0.format,
                                        const: $0.const,
                                        pattern: $0.pattern
                                    ),
                                    predicate: nil
                                )
                            ]
                        )
                    )
                }
            let presentationDefinition = PresentationDefinition(
                format: .init(sdJwt: .init(alg: [.ES256K])),
                inputDescriptors: descriptors
            )

            let container = PresentationExchangeRequest(
                options: .init(domain: UUID().uuidString, challenge: UUID().uuidString),
                presentationDefinition: presentationDefinition
            )
            return try JSONEncoder.didComm().encode(container)
        }
    }
}

/// Represents a request for a presentation exchange, which is part of a credential verification process.
public struct PresentationExchangeRequest: Codable {
    /// Nested structure containing options necessary for a presentation exchange request.
    public struct Options: Codable {
        /// A domain associated with the verifier or the intended audience of the presentation.
        public let domain: String

        /// A challenge that must be signed by the presenter to prove the possession of the credential.
        public let challenge: String
    }

    /// Options specifying the domain and challenge required for the presentation exchange.
    public let options: Options?

    /// The definition of the presentation request detailing what credentials and claims are expected.
    public let presentationDefinition: PresentationDefinition

    /// Initializes a new `PresentationExchangeRequest` with specified options and presentation definition.
    /// - Parameters:
    ///   - options: Options including domain and challenge for the presentation request.
    ///   - presentationDefinition: The detailed definition of the presentation request.
    public init(options: Options?, presentationDefinition: PresentationDefinition) {
        self.options = options
        self.presentationDefinition = presentationDefinition
    }
}
