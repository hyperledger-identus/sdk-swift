import Foundation

/**
 A protocol representing an unknown error in a Prism API response.

 - Note: When an error occurs during an API request/response cycle, the server may return an error object in the response. This object may include an error code, an error message, and possibly an array of underlying errors. If the error received does not conform to the `KnownPrismError` protocol, it will be classified as an `UnknownPrismError`.

 - SeeAlso: `KnownPrismError`
 */
public protocol UnknownPrismError: Error {
    /// The error code returned by the server.
    var code: Int? { get }

    /// The error message returned by the server.
    var message: String? { get }

    /// An array of underlying errors that may have contributed to this error.
    var underlyingErrors: [Error]? { get }
}

/**
 A protocol representing a known error in a Prism API response.

 - Note: When an error occurs during an API request/response cycle, the server may return an error object in the response. This object may include an error code and an error message. If the error received conforms to the `KnownPrismError` protocol, it will be classified as a known error.

 - SeeAlso: `UnknownPrismError`
 */
public protocol KnownPrismError: LocalizedError {
    /// The error code returned by the server.
    var code: Int { get }

    /// The error message returned by the server.
    var message: String { get }
}

extension KnownPrismError {
    public var errorDescription: String? {
        message
    }
}

/**
 An enum representing an unknown error in a Prism API response.

 - Note: When an error occurs during an API request/response cycle, the server may return an error object in the response. This object may include an error code, an error message, and possibly an array of underlying errors. If the error received does not conform to the `KnownPrismError` protocol, it will be classified as an `UnknownPrismError`.

 - SeeAlso: `UnknownPrismError`, `KnownPrismError`
 */
public enum UnknownError: UnknownPrismError {

    /**
     An error case representing a generic "something went wrong" error.

     - Parameters:
        - customMessage: A custom error message, if provided.
        - underlyingErrors: An array of underlying errors that may have contributed to this error, if provided.
     */
    case somethingWentWrongError(customMessage: String? = nil, underlyingErrors: [Error]? = nil)

    /// The error code returned by the server. In this case, the code is always -1.
    public var code: Int? { return -1 }

    /**
     The error message returned by the server.

     - Note: For this enum, the error message will either be a custom message provided at initialization or the default message "Something Went Wrong".

     - SeeAlso: `somethingWentWrongError(customMessage:underlyingErrors:)`
     */
    public var message: String? {
        switch self {
        case let .somethingWentWrongError(customMessage, _):
            return customMessage ?? "Something Went Wrong"
        }
    }

    /**
     An array of underlying errors that may have contributed to this error.

     - Note: For this enum, the array of underlying errors is determined at initialization and returned as-is.

     - SeeAlso: `somethingWentWrongError(customMessage:underlyingErrors:)`
     */
    public var underlyingErrors: [Error]? {
        switch self {
        case let .somethingWentWrongError(_, errors):
            return errors
        }
    }

    public var errorDescription: String? { message }
}

extension UnknownError: Equatable {
    public static func == (lhs: UnknownError, rhs: UnknownError) -> Bool {
        switch (lhs, rhs) {
        case (.somethingWentWrongError, .somethingWentWrongError):
            return lhs.message == rhs.message && lhs.code == rhs.code
        }
    }
}

/**
 An enum representing a known error in a Prism API response.

 - Note: When an error occurs during an API request/response cycle, the server may return an error object in the response. This object may include an error code and an error message. If the error received conforms to the `KnownPrismError` protocol, it will be classified as a known error.

 - SeeAlso: `UnknownPrismError`, `KnownPrismError`
 */
public enum CommonError: KnownPrismError {

    /**
     An error case representing an invalid URL when attempting to send a message.

     - Parameters:
        - url: The invalid URL that caused the error.
     */
    case invalidURLError(url: String)

    /**
     An error case representing an HTTP error returned by the server.

     - Parameters:
        - code: The HTTP error code returned by the server.
        - message: The HTTP error message returned by the server.
     */
    case httpError(code: Int, message: String)

    /**
     An error case representing an invalid regular expression.

     - Parameters:
        - regex: The invalid regular expression that caused the error.
        - invalid: The string that failed to match the regular expression.
     */
    case invalidRegex(regex: String, invalid: String)

    /**
     An error case representing invalid coding or decoding process.

     - Parameters:
        - message: The error message detailing what went wrong during the encoding/decoding process.
     */
    case invalidCoding(message: String)

    /// The error code returned by the server.
    public var code: Int {
        switch self {
        case .invalidURLError:
            return -2
        case let .httpError(code, _):
            return code
        case .invalidRegex:
            return -3
        case .invalidCoding:
            return -4
        }
    }

    /**
     The error message returned by the server.

     - Note: For this enum, the error message is determined based on the specific error case that was encountered.

     - SeeAlso: `invalidURLError(url:)`, `httpError(code:message:)`
     */
    public var message: String {
        switch self {
        case .invalidURLError(let url):
            return "Invalid url while trying to send message: \(url)"
        case let .httpError(code, message):
            return "HTTP Request Error \(code): \(message)"
        case .invalidRegex(let regex, let invalid):
            return "String '\(invalid)' does not match the provided regex: '\(regex)'"
        case .invalidCoding(let message):
            return "Invalid encoding or decoding: \(message)"
        }
    }

    public var description: String {
        "Code \(code): \(message)"
    }
}

extension CommonError: Equatable {
    public static func == (lhs: CommonError, rhs: CommonError) -> Bool {
        lhs.message == rhs.message
    }
}

/**
 An enum representing a known error in a Prism API response.

 - Note: When an error occurs during an API request/response cycle, the server may return an error object in the response. This object may include an error code and an error message. If the error received conforms to the `KnownPrismError` protocol, it will be classified as a known error.

 - SeeAlso: `KnownPrismError`
 */
public enum ApolloError: KnownPrismError {

    /**
     An error case representing invalid mnemonic words.

     - Parameters:
        - invalidWords: An array of invalid mnemonic words that caused the error.
     */
    case invalidMnemonicWord(invalidWords: [String])

    /**
     An error case representing a failure to parse a message string.

     - Note: This error occurs when attempting to convert a message string to UTF8 data.

     - SeeAlso: `Data(_:).utf8`
     */
    case couldNotParseMessageString

    /// An error case representing an invalid JWK format.
    case invalidJWKError

    /// An error case representing a key agreement that does not support verification.
    case keyAgreementDoesNotSupportVerification

    /// An error case representing a failed restoration due to either a missing or invalid identifier.
    case restoratonFailedNoIdentifierOrInvalid

    /**
     An error case representing an invalid key curve.

     - Parameters:
        - invalid: The invalid key curve that caused the error.
        - valid: An array of valid key curves.
     */
    case invalidKeyCurve(invalid: String, valid: [String])

    /**
     An error case representing an invalid key type.

     - Parameters:
        - invalid: The invalid key type that caused the error.
        - valid: An array of valid key types.
     */
    case invalidKeyType(invalid: String, valid: [String])

    /**
     An error case representing missing key parameters.

     - Parameters:
        - missing: An array of missing key parameters that caused the error.
     */
    case missingKeyParameters(missing: [String])

    /// The error code returned by the server.
    public var code: Int {
        switch self {
        case .invalidMnemonicWord:
            return 11
        case .couldNotParseMessageString:
            return 12
        case .invalidJWKError:
            return 13
        case .keyAgreementDoesNotSupportVerification:
            return 14
        case .restoratonFailedNoIdentifierOrInvalid:
            return 15
        case .invalidKeyCurve:
            return 16
        case .invalidKeyType:
            return 17
        case .missingKeyParameters:
            return 18
        }
    }

    /**
     The error message returned by the server.

     - Note: For this enum, the error message is determined based on the specific error case that was encountered.

     - SeeAlso: `invalidMnemonicWord(invalidWords:)`, `couldNotParseMessageString`, `invalidJWKError`
     */
    public var message: String {
        switch self {
        case .invalidMnemonicWord(let words):
            return "The following mnemonic words are invalid: \(words.joined(separator: ", "))"
        case .couldNotParseMessageString:
            return "Could not parse message string"
        case .invalidJWKError:
            return "Invalid JWK format"
        case .keyAgreementDoesNotSupportVerification:
            return "Key agreement does not support verification"
        case .restoratonFailedNoIdentifierOrInvalid:
            return "Restoration failed: no identifier or invalid"
        case .invalidKeyCurve(let invalid, let valid):
            return "Invalid key curve: \(invalid). Valid options are: \(valid.joined(separator: ", "))"
        case .invalidKeyType(let invalid, let valid):
            return "Invalid key type: \(invalid). Valid options are: \(valid.joined(separator: ", "))"
        case .missingKeyParameters(let missing):
            return "Missing key parameters: \(missing.joined(separator: ", "))"
        }
    }
}

extension ApolloError: Equatable {
    public static func == (lhs: ApolloError, rhs: ApolloError) -> Bool {
        lhs.message == rhs.message
    }
}

/**
 An enum representing a known error in a Prism API response.

 - Note: When an error occurs during an API request/response cycle, the server may return an error object in the response. This object may include an error code and an error message. If the error received conforms to the `KnownPrismError` protocol, it will be classified as a known error.

 - SeeAlso: `UnknownPrismError`, `KnownPrismError`
 */
public enum CastorError: KnownPrismError {

    /**
     An error case representing an unsupported key curve.

     - Parameters:
        - curve: The unsupported key curve that caused the error.
     */
    case keyCurveNotSupported(curve: String)

    /// An error case representing an invalid long form DID.
    case invalidLongFormDID

    /**
     An error case representing a DID method ID that does not satisfy a regex pattern.

     - Parameters:
        - regex: The regex pattern that the DID method ID does not satisfy.
     */
    case methodIdIsDoesNotSatisfyRegex(regex: String)

    /**
     An error case representing invalid encoding/decoding of a public key while computing a DID.

     - Parameters:
        - didMethod: The DID method being computed.
        - curve: The key curve that was invalidly encoded/decoded.
     */
    case invalidPublicKeyCoding(didMethod: String, curve: String)

    /**
     An error case representing an invalid DID string.

     - Parameters:
        - str: The invalid DID string that caused the error.
     */
    case invalidDIDString(String)

    /// An error case representing a change in the initial state of a DID.
    case initialStateOfDIDChanged

    /**
     An error case representing the inability to resolve a DID.

     - Parameters:
        - did: The DID that could not be resolved.
        - reason: The reason why the DID could not be resolved.
     */
    case notPossibleToResolveDID(did: String, reason: String)

    /// An error case representing an invalid JWK format.
    case invalidJWKError

    /**
     An error case representing a lack of available resolvers for a given DID method.

     - Parameters:
        - method: The DID method that has no available resolvers.
     */
    case noResolversAvailableForDIDMethod(method: String)

    /// An error case representing inability to retrieve the public key from a document.
    case cannotRetrievePublicKeyFromDocument

    /// An error case representing that a master key was not provided or that it had more than one
    case requiresOneAndJustOneMasterKey

    /// The error code returned by the server.
    public var code: Int {
        switch self {
        case .keyCurveNotSupported:
            return 21
        case .invalidLongFormDID:
            return 22
        case .methodIdIsDoesNotSatisfyRegex:
            return 23
        case .invalidPublicKeyCoding:
            return 24
        case .invalidDIDString:
            return 25
        case .initialStateOfDIDChanged:
            return 26
        case .notPossibleToResolveDID:
            return 27
        case .invalidJWKError:
            return 28
        case .noResolversAvailableForDIDMethod:
            return 29
        case .cannotRetrievePublicKeyFromDocument:
            return 30
        case .requiresOneAndJustOneMasterKey:
            return 31
        }
    }

    /**
     The error message returned by the server.

     - Note: For this enum, the error message is determined based on the specific error case that was encountered.

     - SeeAlso: `keyCurveNotSupported(curve:)`, `invalidLongFormDID`, `methodIdIsDoesNotSatisfyRegex(regex:)`, `invalidPublicKeyCoding(didMethod:curve:)`, `invalidDIDString(String)`, `initialStateOfDIDChanged`, `notPossibleToResolveDID(did:reason:)`, `invalidJWK`
     */
    public var message: String {
        switch self {
        case .keyCurveNotSupported(let curve):
            return "Key curve \(curve) is not supported for this funcionality"
        case .invalidLongFormDID:
            return "Long form prism DID is invalid or changed"
        case .methodIdIsDoesNotSatisfyRegex(let regex):
            return "The Prism DID provided is not passing the regex validation: \(regex)"
        case let .invalidPublicKeyCoding(didMethod, curve):
            return "Invalid encoding/decoding of key (\(curve)) while trying to compute \(didMethod)"
        case .invalidDIDString(let str):
            return "Trying to parse invalid DID String: \(str)"
        case .initialStateOfDIDChanged:
            return "While trying to resolve Prism DID state changed making it invalid"
        case let .notPossibleToResolveDID(did, reason):
            return "Not possible to resolve DID (\(did)) due to \(reason)"
        case .invalidJWKError:
            return "JWK is not in a valid format"
        case .noResolversAvailableForDIDMethod(let method):
            return "No resolvers in castor are able to resolve the method \(method), please provide a resolver"
        case .cannotRetrievePublicKeyFromDocument:
            return "The public keys in the DIDDocument are not in multibase or the multibase is invalid"
        case .requiresOneAndJustOneMasterKey:
            return "The array contains none or more than one master key"
        }
    }
}

extension CastorError: Equatable {
    public static func == (lhs: CastorError, rhs: CastorError) -> Bool {
        lhs.message == rhs.message
    }
}

/**
 An enum representing a known error in a Prism API response.

 - Note: When an error occurs during an API request/response cycle, the server may return an error object in the response. This object may include an error code and an error message. If the error received conforms to the `KnownPrismError` protocol, it will be classified as a known error.

 - SeeAlso: `UnknownPrismError`, `KnownPrismError`
 */
public enum MercuryError: KnownPrismError {

    /// An error case representing the lack of a recipient DID in a message.
    case noRecipientDIDSetError

    /**
     An error case representing the lack of valid services for a DID.

     - Parameters:
        - did: The DID that has no valid services.
     */
    case noValidServiceFoundError(did: String)

    /// An error case representing the lack of a sender DID in a message.
    case noSenderDIDSetError

    /// An error case representing an unknown attachment data type.
    case unknownAttachmentDataTypeError

    /// An error case representing a message attachment without an ID.
    case messageAttachmentWithoutIDError

    /// An error case representing invalid body data in a message.
    case messageInvalidBodyDataError

    /**
     An error case representing a DIDComm error.
     - Parameters:
        - msg: The message describing the error.
        - underlyingErrors: An array of underlying errors that may have contributed to this error, if provided.
    */
    case didcommError(msg: String, underlyingErrors: [Error]? = nil)

    /// The error code returned by the server.
    public var code: Int {
        switch self {
        case .noRecipientDIDSetError:
            return 31
        case .noValidServiceFoundError:
            return 32
        case .noSenderDIDSetError:
            return 33
        case .unknownAttachmentDataTypeError:
            return 34
        case .messageAttachmentWithoutIDError:
            return 35
        case .messageInvalidBodyDataError:
            return 36
        case .didcommError:
            return 37
        }
    }

    /**
     The error message returned by the server.

     - Note: For this enum, the error message is determined based on the specific error case that was encountered.

     - SeeAlso: `noRecipientDIDSetError`, `noValidServiceFoundError(did:)`, `noSenderDIDSetError`, `unknownAttachmentDataTypeError`, `messageAttachmentWithoutIDError`, `messageInvalidBodyDataError`, `didcommError(msg:)`
     */
    public var message: String {
        switch self {
        case .noRecipientDIDSetError:
            return "Message has no recipient set, to send a message please set the \"to\""
        case .noSenderDIDSetError:
            return "Message has no sender set, to send a message please set the \"from\""
        case let .noValidServiceFoundError(did):
            return "The did (\(did)) has no valid services"
        case .unknownAttachmentDataTypeError:
            return "Unknown AttachamentData type was found while decoding message"
        case .messageAttachmentWithoutIDError:
            return "While decoding a message, a message attachment was found without \"id\" this is invalid"
        case .messageInvalidBodyDataError:
            return "While decoding a message, a body was found to be invalid while decoding"
        case let .didcommError(msg, errors):
            let errorsMessages = errors.map {
                "\n" + $0.map { $0.localizedDescription }.joined(separator: "\n")
            } ?? ""
            return "DIDComm error as ocurred with message: \(msg)\nErrors: \(errorsMessages)"
        }
    }
}

extension MercuryError: Equatable {
    public static func == (lhs: MercuryError, rhs: MercuryError) -> Bool {
        lhs.message == rhs.message
    }
}

/**
 An enum representing a known error in a Pluto API response.

 - Note: When an error occurs during an API request/response cycle, the server may return an error object in the response. This object may include an error code and an error message. If the error received conforms to the `KnownPrismError` protocol, it will be classified as a known error.

 - SeeAlso: `UnknownPrismError`, `KnownPrismError`
 */
public enum PlutoError: KnownPrismError {

    /**
     An error case representing missing data persistence.

     - Parameters:
        - type: The type of data that is missing.
        - affecting: The action that is being taken when the error occurs.
     */
    case missingDataPersistence(type: String, affecting: String)

    /**
     An error case representing missing required fields.

     - Parameters:
        - type: The type of data that is missing required fields.
        - fields: An array of the required fields.
     */
    case missingRequiredFields(type: String, fields: [String])

    /**
     An error case representing a duplicate object.

     - Parameters:
        - type: The type of object that is a duplicate.
     */
    case duplication(type: String)

    /// An error case representing an unknown credential type.
    case unknownCredentialTypeError

    /// An error case representing invalid JSON in a credential.
    case invalidCredentialJsonError

    /// An error case representing an invalid combination of algorithm and key type.
    ///
    /// - Parameters:
    ///   - algorithm: The algorithm used.
    ///   - keyType: The key type that is associated with the algorithm.
    case algorithmOrKeyTypeNotValid(algorithm: String, keyType: String)

    /// An error case representing an issue with saving a key to the keychain.
    ///
    /// - Parameter status: The status code representing the error encountered while saving the key.
    case errorSavingKeyOnKeychainWithStatus(OSStatus)

    /// An error case indicating that while a key's item could be retrieved from the keychain, its data could not.
    case errorRetrievingKeyDataInvalid

    /// An error case indicating that a specific key was not found in the keychain.
    ///
    /// - Parameters:
    ///   - service: Optional identifier for the service associated with the key.
    ///   - account: Optional identifier for the account associated with the key.
    ///   - applicationLabel: Optional label for the application associated with the key.
    case errorRetrivingKeyFromKeychainKeyNotFound(service: String? = nil, account: String? = nil, applicationLabel: String? = nil)

    /// An error case representing an issue with retrieving a key from the keychain.
    ///
    /// - Parameter status: The status code representing the error encountered while retrieving the key.
    case errorRetrivingKeyFromKeychainWithStatus(OSStatus)

    /// An error case indicating a failure to retrieve data from a `SecKey` object.
    ///
    /// - Parameters:
    ///   - service: Optional identifier for the service associated with the key.
    ///   - account: Optional identifier for the account associated with the key.
    ///   - applicationLabel: Optional label for the application associated with the key.
    case errorCouldNotRetrieveDataFromSecKeyObject(service: String? = nil, account: String? = nil, applicationLabel: String? = nil)

    /// An error case indicating an issue with creating a `SecKey` object.
    ///
    /// - Parameters:
    ///   - keyType: The type of the key that was being created.
    ///   - keyClass: The class of the key being created.
    case errorCreatingSecKey(keyType: String, keyClass: String)

    /// The error code returned by the server.
    public var code: Int {
        switch self {
        case .missingDataPersistence:
            return 41
        case .missingRequiredFields:
            return 42
        case .duplication:
            return 43
        case .unknownCredentialTypeError:
            return 44
        case .invalidCredentialJsonError:
            return 45
        case .algorithmOrKeyTypeNotValid:
            return 46
        case .errorSavingKeyOnKeychainWithStatus:
            return 47
        case .errorRetrievingKeyDataInvalid:
            return 48
        case .errorRetrivingKeyFromKeychainKeyNotFound:
            return 49
        case .errorRetrivingKeyFromKeychainWithStatus:
            return 50
        case .errorCouldNotRetrieveDataFromSecKeyObject:
            return 51
        case .errorCreatingSecKey:
            return 52
        }
    }

    /**
     The error message returned by the server.

     - Note: For this enum, the error message is determined based on the specific error case that was encountered.

     - SeeAlso: `missingDataPersistence(type:affecting:)`, `missingRequiredFields(type:fields:)`, `duplication(type:)`, `unknownCredentialTypeError`, `invalidCredentialJsonError`
     */
    public var message: String {
        switch self {
        case let .missingDataPersistence(type, affecting):
            return "\(type) is not persisted while trying to add or make changes to \(affecting)"
        case let .missingRequiredFields(type, fields):
            return "\(type) requires the following fields: \(fields.joined(separator: ", "))"
        case .duplication(let type):
            return "Trying to save \(type) with an ID that already exists"
        case .invalidCredentialJsonError:
            return "Could not decode the credential JSON"
        case .unknownCredentialTypeError:
            return "The credential type needs to be JWT or W3C"
        case .algorithmOrKeyTypeNotValid(algorithm: let algorithm, keyType: let keyType):
            return "This algorithm (\(algorithm)) or key type (\(keyType)) are not valid on the platform"
        case .errorSavingKeyOnKeychainWithStatus(let status):
            return "Error saving key on keychain with the following status code: \(status)"
        case .errorRetrievingKeyDataInvalid:
            return "Could retrieve item from keychain but could not retrieve Data of key"
        case .errorRetrivingKeyFromKeychainKeyNotFound(let service, let account, let applicationLabel):
            var message = "Key not found"
            if let service, let account {
                message += " service: \(service) and account: \(account)"
            } else if let applicationLabel {
                message += " applicationLabel: \(applicationLabel)"
            }
            return message
        case .errorRetrivingKeyFromKeychainWithStatus(let status):
            return "Error retrieving key from keychain with the following status code: \(status)"
        case .errorCouldNotRetrieveDataFromSecKeyObject(let service, let account, let applicationLabel):
            var message = "Key not found"
            if let service, let account {
                message += " service: \(service) and account: \(account)"
            } else if let applicationLabel {
                message += " applicationLabel: \(applicationLabel)"
            }
            return message
        case .errorCreatingSecKey(let keyType, let keyClass):
            return "Error creating sec key of type \(keyType) and class \(keyClass)"
        }
    }
}

extension PlutoError: Equatable {
    public static func == (lhs: PlutoError, rhs: PlutoError) -> Bool {
        lhs.message == rhs.message
    }
}

/**
 An enum representing a known error in a Pollux API response.

 - Note: When an error occurs during an API request/response cycle, the server may return an error object in the response. This object may include an error code and an error message. If the error received conforms to the `KnownPrismError` protocol, it will be classified as a known error.

 - SeeAlso: `UnknownPrismError`, `KnownPrismError`
 */
public enum PolluxError: KnownPrismError {

    /// An error case representing an invalid credential. The server could not decode the provided credential.
    case invalidCredentialError

    /// An error case representing an invalid JWT string. The JWT could not be decoded.
    case invalidJWTString

    /// An error case representing an invalid Prism DID. This error is thrown when attempting to create a JWT presentation without a required Prism DID.
    case invalidPrismDID

    /// An error case representing an invalid JWT credential. This error is thrown when attempting to create a JWT presentation without a valid JWTCredential.
    case invalidJWTCredential

    /// An error case when the offer doesnt present enough information like Domain or Challenge
    case offerDoesntProvideEnoughInformation

    /// An error case when the issued credential message doesnt present enough information or unsupported attachment
    case unsupportedIssuedMessage

    /// An error case there is missing an `ExportableKey`
    case requiresExportableKeyForOperation(operation: String)

    /// An error case when the message doesnt present enough information
    case messageDoesntProvideEnoughInformation

    /// An requirement is missing for `CredentialOperationsOptions`
    case missingAndIsRequiredForOperation(type: String)

    /// An error indicating that a credential doesn't provide one or more input descriptors.
    case credentialDoesntProvideOneOrMoreInputDescriptors(path: [String])

    /// An error case indicating that a presentation could not be found in attachments.
    case couldNotFindPresentationInAttachments

    /// An error case indicating an invalid attachment type, with provided supported types.
    case invalidAttachmentType(supportedTypes: [String])

    /// An error case indicating that credential type verification is not supported.
    case credentialTypeVerificationNotSupported(String)

    /// An error case indicating an unsupported attachment format.
    case unsupportedAttachmentFormat(String?)

    /// An error case indicating that the credential algorithm could not be found.
    case couldNotFindCredentialAlgorithm

    /// An error case indicating that the credential is not of the required algorithm for presentation definition.
    case credentialIsNotOfPresentationDefinitionRequiredAlgorithm

    /// An error case indicating that the presentation request could not be found.
    case couldNotFindPresentationRequest(id: String)

    /// An error case indicating that presentation submission is not available.
    case presentationSubmissionNotAvailable

    /// An error case indicating an unsupported submitted format, with valid formats provided.
    case unsupportedSubmittedFormat(string: String, validFormats: [String])

    /// An error case indicating that a credential path is invalid.
    case credentialPathInvalid(path: String)

    /// An error case indicating that the issuer must exist and be a Prism DID.
    case requiresThatIssuerExistsAndIsAPrismDID

    /// An error case indicating that an input cannot be verified due to multiple field errors.
    case cannotVerifyInput(
        name: String? = nil,
        purpose: String? = nil,
        fieldErrors: [Error]
    )

    /// An error case indicating that a specific field in the input cannot be verified, with internal errors listed.
    case cannotVerifyInputField(
        name: String? = nil,
        paths: [String] = [],
        internalErrors: [Error]
    )

    /// An error case indicating that a credential cannot be verified..
    case cannotVerifyCredential(
        credential: String? = nil,
        internalErrors: [Error]
    )

    /// An error case indicating that a specified input path was not found.
    case inputPathNotFound(path: String)

    /// An error case indicating multiple input filter errors.
    case inputFilterErrors(descriptions: [String])

    /// An error case indicating that presentation inputs cannot be verified.
    case cannotVerifyPresentationInputs(errors: [Error])

    /// An error case indicating that the signature is invalid, with internal errors specified.
    case invalidSignature(internalErrors: [Error] = [])

    /// An error case indicating that the credential is revoked.
    /// - Parameter jwtString: The JWT string representing the revoked credential.
    case credentialIsRevoked(jwtString: String)

    /// An error case indicating that the credential is suspended.
    /// - Parameter jwtString: The JWT string representing the suspended credential.
    case credentialIsSuspended(jwtString: String)

    /// An error case indicating that the credential status type is not supported.
    /// - Parameter message: In-dept description of the error.
    case unsupportedCredentialStatusType(message: String)

    /// The error code returned by the server.
    public var code: Int {
        switch self {
        case .invalidCredentialError:
            return 51
        case .invalidJWTString:
            return 52
        case .invalidPrismDID:
            return 53
        case .invalidJWTCredential:
            return 54
        case .offerDoesntProvideEnoughInformation:
            return 55
        case .requiresExportableKeyForOperation:
            return 56
        case .unsupportedIssuedMessage:
            return 57
        case .messageDoesntProvideEnoughInformation:
            return 58
        case .missingAndIsRequiredForOperation:
            return 59
        case .credentialDoesntProvideOneOrMoreInputDescriptors:
            return 60
        case .couldNotFindPresentationInAttachments:
            return 61
        case .invalidAttachmentType:
            return 62
        case .credentialTypeVerificationNotSupported:
            return 63
        case .unsupportedAttachmentFormat:
            return 64
        case .couldNotFindCredentialAlgorithm:
            return 65
        case .credentialIsNotOfPresentationDefinitionRequiredAlgorithm:
            return 66
        case .couldNotFindPresentationRequest:
            return 67
        case .presentationSubmissionNotAvailable:
            return 68
        case .unsupportedSubmittedFormat:
            return 69
        case .credentialPathInvalid:
            return 70
        case .requiresThatIssuerExistsAndIsAPrismDID:
            return 71
        case .cannotVerifyInput:
            return 72
        case .cannotVerifyPresentationInputs:
            return 73
        case .inputFilterErrors:
            return 74
        case .inputPathNotFound:
            return 75
        case .cannotVerifyInputField:
            return 76
        case .invalidSignature:
            return 77
        case .credentialIsRevoked:
            return 78
        case .credentialIsSuspended:
            return 79
        case .cannotVerifyCredential:
            return 80
        case .unsupportedCredentialStatusType:
            return 81
        }
    }

    /**
     The error message returned by the server.

     - Note: For this enum, the error message is determined based on the specific error case that was encountered.

     - SeeAlso: `invalidCredentialError`, `invalidJWTString`, `invalidPrismDID`, `invalidJWTCredential`
     */
    public var message: String {
        switch self {
        case .invalidCredentialError:
            return "Invalid credential, could not decode"
        case .invalidJWTString:
            return "Invalid JWT while decoding credential"
        case .invalidPrismDID:
            return "To create a JWT presentation a Prism DID is required"
        case .invalidJWTCredential:
            return "To create a JWT presentation please provide a valid JWTCredential"
        case .offerDoesntProvideEnoughInformation:
            return "Offer provided doesnt have challenge or domain in the attachments, or there is no Json Attachment"
        case .requiresExportableKeyForOperation(let operation):
            return "Operation \(operation) requires an ExportableKey"
        case .unsupportedIssuedMessage:
            return "Issue message provided doesnt have a valid attachment"
        case .messageDoesntProvideEnoughInformation:
            return "Message provided doesnt have enough information (attachment, type)"
        case .missingAndIsRequiredForOperation(let type):
            return "Operation requires the following parameter \(type)"
        case .credentialDoesntProvideOneOrMoreInputDescriptors(let path):
            return "Credential cannot process presentation because it doesnt has the required inputs \(path)"
        case .couldNotFindPresentationInAttachments:
            return "Could not find the attachments of the presentation in the message"
        case .invalidAttachmentType(let supportedTypes):
            return "Invalid attachment type please use one of the following: \(supportedTypes)"
        case .credentialTypeVerificationNotSupported(let type):
            return "Credential of type \(type) doesnt support verification"
        case .unsupportedAttachmentFormat(let format):
            return "Unsupported attachment format \(format ?? "")"
        case .couldNotFindCredentialAlgorithm:
            return "Could not find cryptographic algorithm for JWT credential"
        case .credentialIsNotOfPresentationDefinitionRequiredAlgorithm:
            return "Presentation definition requires a credential of a different algorithm"
        case .couldNotFindPresentationRequest(let id):
            return "Could not find presentation request \(id)"
        case .presentationSubmissionNotAvailable:
            return "Attachment doesnt provide a presentation submission"
        case .unsupportedSubmittedFormat(string: let string, validFormats: let validFormats):
            return "Invalid format type \(string) please use one of the following: \(validFormats.joined(separator: ", "))"
        case .credentialPathInvalid(path: let path):
            return "No credential could be found at JSONPath: \(path)"
        case .requiresThatIssuerExistsAndIsAPrismDID:
            return "This verification requires JWT issuer to exist and be a valid DID"
        case .cannotVerifyInput(let name, let purpose, let fieldErrors):
            let errors = fieldErrors.map { " - \(errorMessage($0))" }.joined(separator: "\n")
            return
"""
Cannot verify input descriptor \(name.map { "with name: \($0)"} ?? ""), \(purpose.map { "for \($0)" } ?? "") with errors: \n \(errors)
"""
        case .cannotVerifyPresentationInputs(errors: let errors):
            let errors = errors.map { " - \(errorMessage($0))" }.joined(separator: "\n")
            return
"""
Cannot verify presentation with errors: \n \(errors)
"""
        case .inputFilterErrors(descriptions: let descriptions):
            return """
Input filter error: \(descriptions.joined(separator: ", "))
"""
        case .inputPathNotFound(path: let path):
            return "Input value could not be found for path \(path)"
        case .cannotVerifyInputField(name: let name, paths: let paths, internalErrors: let internalErrors):
            let errors = internalErrors.map { " - \(errorMessage($0))" }.joined(separator: "\n")
            return
"""
Cannot verify input descriptor field \(name.map { "with name: \($0)"} ?? ""), with paths: \(paths.joined(separator: ", ")) with errors: \n \(errors)
"""
        case .invalidSignature:
            return "Could not verify one or more JWT signatures"

        case .credentialIsRevoked(let jwtString):
            return "Credential (\(jwtString)) is revoked"

        case .credentialIsSuspended(let jwtString):
            return "Credential (\(jwtString)) is suspended"
        case .cannotVerifyCredential(let credential, let fieldErrors):
            let errors = fieldErrors.map { " - \(errorMessage($0))" }.joined(separator: "\n")
            return
"""
Cannot verify credential: \(credential.map { "with name: \($0)"} ?? ""), with errors: \n \(errors)
"""
        case .unsupportedCredentialStatusType(let message):
            return "Could not verify credential status: \(message)"
        }
    }
}


extension PolluxError: Equatable {
    public static func == (lhs: PolluxError, rhs: PolluxError) -> Bool {
        lhs.message == rhs.message
    }
}

/**
 KeyError` is an enumeration representing known errors related to key management.

 - Note: When an error occurs during an API request/response cycle, the server may return an error object in the response. This object may include an error code and an error message. If the error received conforms to the `KnownPrismError` protocol, it will be classified as a known error.

 - SeeAlso: `UnknownPrismError`, `KnownPrismError`
 */
public enum KeyError: KnownPrismError {

    /// An error indicating that a key requires certain protocol conformances that are not met.
    /// The associated value `conformations` lists the names of the required protocols as Strings.
    case keyRequiresConformation(conformations: [String])

    /// The error code returned by the server. For `keyRequiresConformation`, the error code is 61.
    public var code: Int {
        switch self {
        case .keyRequiresConformation:
            return 61
        }
    }

    /// A human-readable message describing the error. For `keyRequiresConformation`, it lists the required protocol conformances.
    public var message: String {
        switch self {
        case .keyRequiresConformation(let conformations):
            return "Key requires conformation with the following protocols: \(conformations.joined(separator: ", "))"
        }
    }

    /// A full description of the error, including its code and message.
    public var description: String {
        "Code \(code): \(message)"
    }
}

extension KeyError: Equatable {
    public static func == (lhs: KeyError, rhs: KeyError) -> Bool {
        lhs.message == rhs.message
    }
}

private func errorMessage(_ error: Error) -> String {
    switch error {
    case let localizable as LocalizedError:
        guard let message = localizable.errorDescription else {
            return localizable.localizedDescription
        }
        return message
    default:
        return error.localizedDescription
    }
}
