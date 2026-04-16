# Apollo Errors

This is an enum definition named `ApolloError` that conforms to `KnownPrismError` protocol. The enum has three cases, and each case represents an error scenario with a message that describes the reason for the error.

## Error 1: Invalid Mnemonic Word

Code: 11
Message: "The following mnemonic words are invalid: {invalidWords}"

This error occurs when the given mnemonic words are invalid. The reason for this error could be due to the following possible reasons:

- The mnemonic phrase is incorrect.
- The given mnemonic word is not a valid English word.
- The order of the mnemonic words is incorrect.

The recovery solutions for this error are:

- Check if the mnemonic phrase is correct.
- Check if the given words are valid English words.
- Verify if the order of the words is correct.

## Error 2: Could Not Parse Message String

Code: 12
Message: "Could not get UTF8 Data from message string"

This error occurs when the UTF8 data from the message string could not be retrieved. The reason for this error could be due to the following possible reasons:

- The message string is empty.
- The message string has invalid characters.
- There is an issue with the encoding of the message string.

The recovery solutions for this error are:

- Check if the message string is not empty.
- Check if the message string contains only valid characters.
- Verify if the encoding of the message string is correct.

## Error 3: Invalid JWK Error

Code: 13
Message: "JWK is not in a valid format"

This error occurs when the JWK (JSON Web Key) is not in a valid format. The reason for this error could be due to the following possible reasons:

- The JWK is incomplete.
- The JWK contains invalid fields.
- The JWK is not in the correct format.

The recovery solutions for this error are:

- Check if the JWK is complete.
- Verify if the fields in the JWK are valid.
- Verify if the JWK is in the correct format.
- Code and Message for Each Error
