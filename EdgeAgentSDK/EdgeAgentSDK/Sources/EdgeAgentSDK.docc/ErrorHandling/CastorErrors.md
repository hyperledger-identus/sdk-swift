# Castor Errors

This is an enum definition named `CastorError` that conforms to `KnownPrismError` protocol. The enum has several cases, and each case represents an error scenario with a message that describes the reason for the error.

## Error 1: Key Curve Not Supported

Code: 21
Message: "Key curve {curve} is not supported for this functionality"

This error occurs when a key curve is not supported for a specific functionality. The reason for this error could be due to the following possible reasons:

- The key curve is not supported for the specific functionality.
- The key curve is not valid.

The recovery solutions for this error are:

- Check if the key curve is supported for the specific functionality.
- Verify if the key curve is valid.

## Error 2: Invalid Long Form DID

Code: 22
Message: "Long form prism DID is invalid or changed"

This error occurs when the Long form prism DID is invalid or changed. The reason for this error could be due to the following possible reasons:

- The Long form prism DID is invalid.
- The Long form prism DID has been changed.

The recovery solutions for this error are:

- Check if the Long form prism DID is valid.
- Verify if the Long form prism DID has been changed.

###  Error 3: Method ID Does Not Satisfy Regex

Code: 23
Message: "The Prism DID provided is not passing the regex validation: {regex}"

This error occurs when the Prism DID provided is not passing the regex validation. The reason for this error could be due to the following possible reasons:

- The Prism DID is not passing the regex validation.

##  Error 4: Invalid Public Key Coding

Code: 24
Message: "Invalid encoding/decoding of key ({curve}) while trying to compute {didMethod}"

This error occurs when there is invalid encoding/decoding of key while trying to compute a DID method. The reason for this error could be due to the following possible reasons:

- There is invalid encoding/decoding of the key.
- There is an issue with the DID method.

The recovery solutions for this error are:

- Verify if there is valid encoding/decoding of the key.
- Check if the DID method is correct.

##  Error 5: Invalid DID String

Code: 25
Message: "Trying to parse invalid DID String: {str}"

This error occurs when trying to parse an invalid DID string. The reason for this error could be due to the following possible reasons:

- The DID string is not in the correct format.
- The DID string is not valid.

The recovery solutions for this error are:

- Verify if the DID string is in the correct format.
- Check if the DID string is valid.

## Error 6: Initial State of DID Changed

Code: 26
Message: "While trying to resolve Prism DID state changed making it invalid"

This error occurs when trying to resolve a Prism DID, the initial state changed, making it invalid. The reason for this error could be due to the following possible reasons:

- The initial state of the Prism DID has changed.
- There is an issue with resolving the Prism DID.

The recovery solutions for this error are:

- Check if the initial state of the Prism DID has changed.

## Error 7: Not Possible to Resolve DID

Code: 27
Message: "Not possible to resolve DID ({did}) due to {reason}"

This error occurs when it is not possible to resolve a Prism DID due to a specific reason. The reason for this error could be due to the following possible reasons:

- The Prism DID is not resolvable.
- There is an issue with the resolver.

The recovery solutions for this error are:

- Check if the Prism DID is resolvable.
- Verify if there is an issue with the resolver.

##  Error 8: Invalid JWK Error

Code: 28
Message: "JWK is not in a valid format"

This error occurs when the JWK (JSON Web Key) is not in a valid format. The reason for this error could be due to the following possible reasons:

- The JWK is incomplete.
- The JWK contains invalid fields.
- The JWK is not in the correct format.

The recovery solutions for this error are:

- Check if the JWK is complete.
- Verify if the fields in the JWK are valid.
- Verify if the JWK is in the correct format.

## Error 9: No Resolvers Available for DID Method

Code: 29
Message: "No resolvers in castor are able to resolve the method {method}, please provide a resolver"

This error occurs when no resolvers in Castor are able to resolve the method. The reason for this error could be due to the following possible reasons:

- There are no resolvers available for the DID method.
- There is an issue and the resolver cannot resolve the DID.

The recovery solutions for this error are:

- Check if there are resolvers available for the DID method.
- Verify if there is an issue with the resolver.
