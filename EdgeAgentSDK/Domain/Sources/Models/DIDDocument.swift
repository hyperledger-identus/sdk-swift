import Core
import Foundation

/// Represents a Core Property in a DID Document.
/// This allows for extensability of the properties.
/// /// As specified in [w3 standards](https://www.w3.org/TR/did-core/#data-model)
public protocol DIDDocumentCoreProperty: RawCodable {}

/// Represents a DIDDocument with ``DID`` and ``[DIDDocumentCoreProperty]``
/// As specified in [w3 standards](https://www.w3.org/TR/did-core/#data-model)
/// A DID Document consists of a DID, public keys, authentication protocols, service endpoints, and other metadata. It is used to verify the authenticity and identity of the DID, and to discover and interact with the associated subjects or objects.
public struct DIDDocument: RawCodable{

    enum CodingKeys: CodingKey {
        case id
        case alsoKnownAs
        case controller
        case service
        case verificationMethod
        case authentication
        case assertionMethod
        case keyAgreement
        case capabilityInvocation
        case capabilityDelegation
    }

    struct URLOrVerificationMethodCoder: RawCodable {
        let raw: AnyCodable?

        init(raw: AnyCodable? = nil) {
            self.raw = raw
        }

        init(from decoder: any Decoder) throws {
            self.raw = try AnyCodable(from: decoder)
        }

        func encode(to encoder: any Encoder) throws {
            guard let raw else { return }
            try raw.encode(to: encoder)
        }
    }

    /// Represents a Verification Method, which is a public key or other evidence used to authenticate the identity of a Decentralized Identifier (DID) or other subject or object.
    ///
    /// A Verification Method consists of a type (indicating the type of key or evidence), a public key or other data, and optional metadata such as a controller (the DID that controls the verification method) and purpose (the intended use of the verification method). It is typically included in a DID Document or other authentication credential.
    public struct VerificationMethod: RawCodable {
        /// The ID of the verification method, represented as a DID URL.
        public let id: DIDUrl

        /// The controller of the verification method, represented as a DID.
        public let controller: DID

        /// The type of the verification method, indicated as a string (e.g. "EcdsaSecp256k1VerificationKey2019").
        public let type: String

        /// The public key of the verification method, represented as a JSON Web Key (JWK).
        public let publicKeyJwk: [String: String]?

        /// The public key of the verification method, represented as a multibase encoded string.
        public let publicKeyMultibase: String?
        public let raw: AnyCodable?

        public init(
            id: DIDUrl,
            controller: DID,
            type: String,
            publicKeyJwk: [String: String]? = nil,
            publicKeyMultibase: String? = nil,
            raw: AnyCodable? = nil
        ) {
            self.id = id
            self.controller = controller
            self.type = type
            self.publicKeyJwk = publicKeyJwk
            self.publicKeyMultibase = publicKeyMultibase
            self.raw = raw
        }
//
//        public var publicKey: PublicKey? {
//            publicKeyMultibase
//                .flatMap { Data(base64Encoded: $0) }
//                .map { PublicKey(curve: type, value: $0) }
//        }
    }

    /// Represents a Service, which is a capability or endpoint offered by a Decentralized Identifier (DID) or other subject or object.
    ///
    /// A Service consists of an ID, type, and service endpoint, as well as optional metadata such as a priority and a description. It is typically included in a DID Document and can be used to discover and interact with the associated DID or subject or object.
    public struct Service: RawCodable {

        enum CodingKeys: CodingKey {
            case id
            case type
            case serviceEndpoint
        }

        /// Represents a service endpoint, which is a URI and other information that indicates how to access the service.
        public struct ServiceEndpoint: RawCodable {

            public enum CodingKeys: CodingKey {
                case uri
                case accept
                case routingKeys
            }

            /// The URI of the service endpoint.
            public let uri: String

            /// The types of content that the service endpoint can accept.
            public let accept: [String]

            /// The routing keys that can be used to route messages to the service endpoint.
            public let routingKeys: [String]
            public let raw: AnyCodable?

            public init(
                uri: String,
                accept: [String] = [],
                routingKeys: [String] = [],
                raw: AnyCodable? = nil
            ) {
                self.uri = uri
                self.accept = accept
                self.routingKeys = routingKeys
                self.raw = raw
            }

            public init(from decoder: any Decoder) throws {
                if
                    let singleValueContainer = try? decoder.singleValueContainer(),
                    let uri = try? singleValueContainer.decode(String.self)
                {
                    self.uri = uri
                    self.accept = []
                    self.routingKeys = []

                } else {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    self.uri = try container.decode(String.self, forKey: .uri)
                    self.accept = try container.decode([String].self, forKey: .accept)
                    self.routingKeys = try container.decode([String].self, forKey: .routingKeys)
                }
                self.raw = try AnyCodable(from: decoder)
            }

            public func encode(to encoder: any Encoder) throws {
                guard let raw else {
                    guard accept.isEmpty || routingKeys.isEmpty else {
                        var container = encoder.singleValueContainer()
                        try container.encode(uri)
                        return
                    }
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(uri, forKey: .uri)
                    try container.encode(accept, forKey: .accept)
                    try container.encode(routingKeys, forKey: .routingKeys)
                    return
                }
                try raw.encode(to: encoder)
            }
        }

        /// The ID of the service, represented as a string.
        public let id: String?

        /// The types of the service, indicated as an array of strings.
        public let type: OneOrMany<String>

        /// The service endpoint of the service.
        public let serviceEndpoint: OneOrMany<ServiceEndpoint>
        public let raw: AnyCodable?

        public init(
            id: String,
            type: OneOrMany<String>,
            serviceEndpoint: OneOrMany<ServiceEndpoint>,
            raw: AnyCodable? = nil
        ) {
            self.id = id
            self.type = type
            self.serviceEndpoint = serviceEndpoint
            self.raw = raw
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decodeIfPresent(String.self, forKey: .id)
            self.type = try container.decode(OneOrMany<String>.self, forKey: .type)
            self.serviceEndpoint = try container.decode(OneOrMany<ServiceEndpoint>.self, forKey: .serviceEndpoint)
            self.raw = try AnyCodable(from: decoder)
        }

        public func encode(to encoder: any Encoder) throws {
            guard let raw else {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encodeIfPresent(self.id, forKey: .id)
                try container.encode(self.type, forKey: .type)
                try container.encode(self.serviceEndpoint, forKey: .serviceEndpoint)
                return
            }
            try raw.encode(to: encoder)
        }
    }

    /// Represents a "also known as" property, which is a list of alternative names or identifiers for a Decentralized Identifier (DID) or other subject or object.
    ///
    /// The "also known as" property is typically included in a DID Document and can be used to associate the DID or subject or object with other names or identifiers.
    public struct AlsoKnownAs: DIDDocumentCoreProperty {
        /// The values of the "also known as" property, represented as an array of strings.
        public let values: Set<DID>
        public let raw: AnyCodable?

        public init(values: Set<DID>, raw: AnyCodable? = nil) {
            self.values = values
            self.raw = raw
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            self.values = Set(try container.decode(OneOrMany<DID>.self).array)
            self.raw = try AnyCodable(from: decoder)
        }

        public func encode(to encoder: any Encoder) throws {
            guard let raw else {
                var container = encoder.singleValueContainer()
                try container.encode(self.values)
                return
            }
            try raw.encode(to: encoder)
        }
    }

    /// Represents a "controller" property, which is a list of Decentralized Identifiers (DIDs) that control the associated DID or subject or object.
    ///
    /// The "controller" property is typically included in a DID Document and can be used to indicate who has the authority to update or deactivate the DID or subject or object.
    public struct Controller: DIDDocumentCoreProperty {
        /// The values of the "controller" property, represented as an array of DIDs.
        public let values: Set<DID>
        public let raw: AnyCodable?

        public init(values: Set<DID>, raw: AnyCodable? = nil) {
            self.values = values
            self.raw = raw
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            self.values = Set(try container.decode(OneOrMany<DID>.self).array)
            self.raw = try AnyCodable(from: decoder)
        }

        public func encode(to encoder: any Encoder) throws {
            guard let raw else {
                var container = encoder.singleValueContainer()
                try container.encode(self.values)
                return
            }
            try raw.encode(to: encoder)
        }
    }

    /// Represents a "verification methods" property, which is a list of Verification Methods associated with a Decentralized Identifier (DID) or other subject or object.
    ///
    /// The "verification methods" property is typically included in a DID Document and can be used to authenticate the identity of the DID or subject or object.
    public struct VerificationMethods: DIDDocumentCoreProperty {
        /// The values of the "verification methods" property, represented as an array of VerificationMethod structs.
        public let values: [VerificationMethod]
        public let raw: AnyCodable?

        public init(values: [VerificationMethod], raw: AnyCodable? = nil) {
            self.values = values
            self.raw = raw
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            self.values = try container.decode([VerificationMethod].self)
            self.raw = try AnyCodable(from: decoder)
        }

        public func encode(to encoder: any Encoder) throws {
            guard let raw else {
                var container = encoder.singleValueContainer()
                try container.encode(self.values)
                return
            }
            try raw.encode(to: encoder)
        }
    }

    /// Represents a "services" property, which is a list of Services associated with a Decentralized Identifier (DID) or other subject or object.
    ///
    /// The "services" property is typically included in a DID Document and can be used to discover and interact with the associated DID or subject or object.
    public struct Services: DIDDocumentCoreProperty {
        /// The values of the "services" property, represented as an array of Service structs.
        public let values: [Service]
        public let raw: AnyCodable?

        public init(values: [Service], raw: AnyCodable? = nil) {
            self.values = values
            self.raw = raw
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            self.values = try container.decode([Service].self)
            self.raw = try AnyCodable(from: decoder)
        }

        public func encode(to encoder: any Encoder) throws {
            guard let raw else {
                var container = encoder.singleValueContainer()
                try container.encode(self.values)
                return
            }
            try raw.encode(to: encoder)
        }
    }

    /// Represents an "authentication" property, which is a list of URIs and Verification Methods that can be used to authenticate the associated DID or subject or object.
    ///
    /// The "authentication" property is typically included in a DID Document and can be used to verify the identity of the DID or subject or object.
    public struct Authentication: DIDDocumentCoreProperty {
        /// The URIs of the authentication property.
        public let urls: [String]

        /// The Verification Methods of the authentication property.
        public let verificationMethods: [VerificationMethod]
        public let raw: AnyCodable?

        public init(urls: [String], verificationMethods: [VerificationMethod], raw: AnyCodable? = nil) {
            self.urls = urls
            self.verificationMethods = verificationMethods
            self.raw = raw
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            let decoded = try container.decode([URLOrVerificationMethodCoder].self)
            self.urls = decoded.compactMap { try? $0.decodedAs() }
            self.verificationMethods = decoded.compactMap { try? $0.decodedAs() }
            self.raw = try AnyCodable(from: decoder)
        }

        public func encode(to encoder: any Encoder) throws {
            guard let raw else {
                var container = encoder.singleValueContainer()
                let mapped = urls.map { URLOrVerificationMethodCoder(raw: AnyCodable($0)) } + verificationMethods.map { URLOrVerificationMethodCoder(raw: AnyCodable($0))}
                try container.encode(mapped)
                return
            }
            try raw.encode(to: encoder)
        }
    }

    /// Represents an "assertion method" property, which is a list of URIs and Verification Methods that can be used to assert the authenticity of a message or credential associated with a DID or other subject or object.
    ///
    /// The "assertion method" property is typically included in a DID Document and can be used to verify the authenticity of messages or credentials related to the DID or subject or object.
    public struct AssertionMethod: DIDDocumentCoreProperty {
        /// The URIs of the assertion method property.
        public let urls: [String]

        /// The Verification Methods of the assertion method property.
        public let verificationMethods: [VerificationMethod]
        public let raw: AnyCodable?

        public init(urls: [String], verificationMethods: [VerificationMethod], raw: AnyCodable? = nil) {
            self.urls = urls
            self.verificationMethods = verificationMethods
            self.raw = raw
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            let decoded = try container.decode([URLOrVerificationMethodCoder].self)
            self.urls = decoded.compactMap { try? $0.decodedAs() }
            self.verificationMethods = decoded.compactMap { try? $0.decodedAs() }
            self.raw = try AnyCodable(from: decoder)
        }

        public func encode(to encoder: any Encoder) throws {
            guard let raw else {
                var container = encoder.singleValueContainer()
                let mapped = urls.map { URLOrVerificationMethodCoder(raw: AnyCodable($0)) } + verificationMethods.map { URLOrVerificationMethodCoder(raw: AnyCodable($0))}
                try container.encode(mapped)
                return
            }
            try raw.encode(to: encoder)
        }
    }

    /// Represents a "key agreement" property, which is a list of URIs and Verification Methods that can be used to establish a secure communication channel with a DID or other subject or object.
    ///
    /// The "key agreement" property is typically included in a DID Document and can be used to establish a secure communication channel with the DID or subject or object.
    public struct KeyAgreement: DIDDocumentCoreProperty {
        /// The URIs of the key agreement property.
        public let urls: [String]

        /// The Verification Methods of the key agreement property.
        public let verificationMethods: [VerificationMethod]
        public let raw: AnyCodable?

        /// Initializes the KeyAgreement struct with an array of URIs and an array of VerificationMethods.
        public init(urls: [String], verificationMethods: [VerificationMethod], raw: AnyCodable? = nil) {
            self.urls = urls
            self.verificationMethods = verificationMethods
            self.raw = raw
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            let decoded = try container.decode([URLOrVerificationMethodCoder].self)
            self.urls = decoded.compactMap { try? $0.decodedAs() }
            self.verificationMethods = decoded.compactMap { try? $0.decodedAs() }
            self.raw = try AnyCodable(from: decoder)
        }

        public func encode(to encoder: any Encoder) throws {
            guard let raw else {
                var container = encoder.singleValueContainer()
                let mapped = urls.map { URLOrVerificationMethodCoder(raw: AnyCodable($0)) } + verificationMethods.map { URLOrVerificationMethodCoder(raw: AnyCodable($0))}
                try container.encode(mapped)
                return
            }
            try raw.encode(to: encoder)
        }
    }

    /// Represents a "capability invocation" property, which is a list of URIs and Verification Methods that can be used to invoke a specific capability or service provided by a DID or other subject or object.
    ///
    /// The "capability invocation" property is typically included in a DID Document and can be used to invoke a specific capability or service provided by the DID or subject or object.
    public struct CapabilityInvocation: DIDDocumentCoreProperty {
        /// The URIs of the capability invocation property.
        public let urls: [String]

        /// The Verification Methods of the capability invocation property.
        public let verificationMethods: [VerificationMethod]
        public let raw: AnyCodable?

        public init(urls: [String], verificationMethods: [VerificationMethod], raw: AnyCodable? = nil) {
            self.urls = urls
            self.verificationMethods = verificationMethods
            self.raw = raw
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            let decoded = try container.decode([URLOrVerificationMethodCoder].self)
            self.urls = decoded.compactMap { try? $0.decodedAs() }
            self.verificationMethods = decoded.compactMap { try? $0.decodedAs() }
            self.raw = try AnyCodable(from: decoder)
        }

        public func encode(to encoder: any Encoder) throws {
            guard let raw else {
                var container = encoder.singleValueContainer()
                let mapped = urls.map { URLOrVerificationMethodCoder(raw: AnyCodable($0)) } + verificationMethods.map { URLOrVerificationMethodCoder(raw: AnyCodable($0))}
                try container.encode(mapped)
                return
            }
            try raw.encode(to: encoder)
        }
    }

    /// Represents a "capability delegation" property, which is a list of URIs and Verification Methods that can be used to delegate a specific capability or service provided by a DID or other subject or object to another subject or object.
    ///
    /// The "capability delegation" property is typically included in a DID Document and can be used to delegate a specific capability or service provided by the DID or subject or object.
    public struct CapabilityDelegation: DIDDocumentCoreProperty {
        /// The URIs of the capability delegation property.
        public let urls: [String]

        /// The Verification Methods of the capability delegation property.
        public let verificationMethods: [VerificationMethod]
        public let raw: AnyCodable?

        public init(urls: [String], verificationMethods: [VerificationMethod], raw: AnyCodable? = nil) {
            self.urls = urls
            self.verificationMethods = verificationMethods
            self.raw = raw
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            let decoded = try container.decode([URLOrVerificationMethodCoder].self)
            self.urls = decoded.compactMap { try? $0.decodedAs() }
            self.verificationMethods = decoded.compactMap { try? $0.decodedAs() }
            self.raw = try AnyCodable(from: decoder)
        }

        public func encode(to encoder: any Encoder) throws {
            guard let raw else {
                var container = encoder.singleValueContainer()
                let mapped = urls.map { URLOrVerificationMethodCoder(raw: AnyCodable($0)) } + verificationMethods.map { URLOrVerificationMethodCoder(raw: AnyCodable($0))}
                try container.encode(mapped)
                return
            }
            try raw.encode(to: encoder)
        }
    }

    public let id: DID
    public let coreProperties: [DIDDocumentCoreProperty]
    public let raw: AnyCodable?

    public init(
        id: DID,
        coreProperties: [DIDDocumentCoreProperty],
        raw: AnyCodable? = nil
    ) {
        self.id = id
        self.coreProperties = coreProperties
        self.raw = raw
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(DID.self, forKey: .id)
        let controller = try container.decodeIfPresent(Controller.self, forKey: .controller)
        let alsoKnownAs = try container.decodeIfPresent(AlsoKnownAs.self, forKey: .alsoKnownAs)
        let verificationMethods = try container.decodeIfPresent(VerificationMethods.self, forKey: .verificationMethod)
        let authenticationMethods = try container.decodeIfPresent(Authentication.self, forKey: .authentication)
        let assertionMethods = try container.decodeIfPresent(AssertionMethod.self, forKey: .assertionMethod)
        let keyAgreementMethods = try container.decodeIfPresent(KeyAgreement.self, forKey: .keyAgreement)
        let capabilityInvocationMethods = try container.decodeIfPresent(CapabilityInvocation.self, forKey: .capabilityInvocation)
        let capabilityDelegationMethods = try container.decodeIfPresent(CapabilityDelegation.self, forKey: .capabilityDelegation)
        let services = try container.decodeIfPresent(Services.self, forKey: .service)

        let coreProperties: [DIDDocumentCoreProperty?] = [
            controller,
            alsoKnownAs,
            verificationMethods,
            authenticationMethods,
            assertionMethods,
            keyAgreementMethods,
            capabilityInvocationMethods,
            capabilityDelegationMethods,
            services
        ]
        self.coreProperties = coreProperties.compactMap { $0 }
        self.raw = try AnyCodable(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        guard let raw else {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            let alsoKnownAs = coreProperties.first { $0 is AlsoKnownAs } as? AlsoKnownAs
            let controller = coreProperties.first { $0 is Controller } as? Controller
            let verificationMethods = coreProperties.first { $0 is VerificationMethods } as? VerificationMethods
            let authenticationMethods = coreProperties.first { $0 is Authentication } as? Authentication
            let assertionMethods = coreProperties.first { $0 is AssertionMethod } as? AssertionMethod
            let keyAgreementMethods = coreProperties.first { $0 is KeyAgreement } as? KeyAgreement
            let capabilityInvocationMethods = coreProperties.first { $0 is CapabilityInvocation } as? CapabilityInvocation
            let capabilityDelegationMethods = coreProperties.first { $0 is CapabilityDelegation } as? CapabilityDelegation
            let services = coreProperties.first { $0 is Services } as? Services
            try container.encodeIfPresent(controller, forKey: .controller)
            try container.encodeIfPresent(alsoKnownAs, forKey: .alsoKnownAs)
            try container.encodeIfPresent(verificationMethods, forKey: .verificationMethod)
            try container.encodeIfPresent(authenticationMethods, forKey: .authentication)
            try container.encodeIfPresent(assertionMethods, forKey: .assertionMethod)
            try container.encodeIfPresent(keyAgreementMethods, forKey: .keyAgreement)
            try container.encodeIfPresent(capabilityInvocationMethods, forKey: .capabilityInvocation)
            try container.encodeIfPresent(capabilityDelegationMethods, forKey: .capabilityDelegation)
            try container.encodeIfPresent(services, forKey: .service)
            return
        }
        try raw.encode(to: encoder)
    }

    public var controller: Set<DID> {
        guard
            let property = coreProperties
                .first(where: { $0 is Controller })
                .map({ $0 as? Controller }),
            let controllerProperty = property
        else { return [] }
        return Set(controllerProperty.values)
    }

    public var alsoKnownAs: Set<DID> {
        guard
            let property = coreProperties
                .first(where: { $0 is AlsoKnownAs })
                .map({ $0 as? Controller }),
            let controllerProperty = property
        else { return [] }
        return Set(controllerProperty.values)
    }

    public var authenticate: [VerificationMethod] {
        guard
            let property = coreProperties
                .first(where: { $0 is Authentication })
                .map({ $0 as? Authentication }),
            let authenticateProperty = property
        else { return [] }

        guard authenticateProperty.urls.isEmpty else {
            return authenticateProperty.urls.compactMap { uri in
                verificationMethods.first { $0.id.string == uri }
            } + authenticateProperty.verificationMethods
        }
        return authenticateProperty.verificationMethods
    }

    public var assertion: [VerificationMethod] {
        guard
            let property = coreProperties
                .first(where: { $0 is AssertionMethod })
                .map({ $0 as? AssertionMethod }),
            let assertionProperty = property
        else { return [] }

        guard assertionProperty.urls.isEmpty else {
            return assertionProperty.urls.compactMap { uri in
                verificationMethods.first { $0.id.string == uri }
            } + assertionProperty.verificationMethods
        }
        return assertionProperty.verificationMethods
    }

    public var keyAgreement: [VerificationMethod] {
        guard
            let property = coreProperties
                .first(where: { $0 is KeyAgreement })
                .map({ $0 as? KeyAgreement }),
            let keyAgreementProperty = property
        else { return [] }

        guard keyAgreementProperty.urls.isEmpty else {
            return keyAgreementProperty.urls.compactMap { uri in
                verificationMethods.first { $0.id.string == uri }
            } + keyAgreementProperty.verificationMethods
        }
        return keyAgreementProperty.verificationMethods
    }

    public var capabilityInvocation: [VerificationMethod] {
        guard
            let property = coreProperties
                .first(where: { $0 is CapabilityInvocation })
                .map({ $0 as? CapabilityInvocation }),
            let capabilityInvocationProperty = property
        else { return [] }

        guard capabilityInvocationProperty.urls.isEmpty else {
            return capabilityInvocationProperty.urls.compactMap { uri in
                verificationMethods.first { $0.id.string == uri }
            } + capabilityInvocationProperty.verificationMethods
        }
        return capabilityInvocationProperty.verificationMethods
    }

    public var capabilityDelegation: [VerificationMethod] {
        guard
            let property = coreProperties
                .first(where: { $0 is CapabilityDelegation })
                .map({ $0 as? CapabilityDelegation }),
            let capabilityDelegationProperty = property
        else { return [] }

        guard capabilityDelegationProperty.urls.isEmpty else {
            return capabilityDelegationProperty.urls.compactMap { uri in
                verificationMethods.first { $0.id.string == uri }
            } + capabilityDelegationProperty.verificationMethods
        }
        return capabilityDelegationProperty.verificationMethods
    }

    public var verificationMethods: [VerificationMethod] {
        guard
            let property = coreProperties
                .first(where: { $0 is VerificationMethods })
                .map({ $0 as? VerificationMethods }),
            let verificationMethodsProperty = property
        else { return [] }

        return verificationMethodsProperty.values
    }

    public var services: [Service] {
        guard
            let property = coreProperties
                .first(where: { $0 is Services })
                .map({ $0 as? Services }),
            let servicesProperty = property
        else { return [] }

        return servicesProperty.values
    }
}
