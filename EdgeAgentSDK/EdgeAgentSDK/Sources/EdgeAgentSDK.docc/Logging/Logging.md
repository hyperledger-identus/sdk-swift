# Logging

## Setup

To set up logging, you can use the setupLogging method in the EdgeAgent class, passing in a dictionary of LogComponent and LogLevel pairs. LogComponent is an enumeration that represents different components in the SDK, such as prism, didcomm, and apollo. LogLevel is an enumeration that represents different levels of logging, such as debug, info, and error.

Here's an example of setting up logging:

```swift
let logLevels: [LogComponent: LogLevel] = [
    .edgeAgent: .debug,
    .mercury: .debug,
    .apollo: .info
]
EdgeAgent.setupLogging(logLevels: logLevels)
```

## Logging messages

The SDK will log events at different log levels using the debug, info, warning, error, etc methods:

```swift
logger.debug(message: "This is a debug message.")
logger.info(message: "This is an info message.")
logger.warning(message: "This is a warning message.")
logger.error(message: "This is an error message.")
```

The output of this code will look something like this:

```
2022-03-01T14:54:06+0000 debug [ Module ] : This is a debug message.
2022-03-01T14:54:06+0000 info [ Module ] : This is an info message.
2022-03-01T14:54:06+0000 warning [ Module ] : This is a warning message.
2022-03-01T14:54:06+0000 error [ Module ] : This is an error message.
```

The first part of the output shows the timestamp of the log message, followed by the logging level, the logging component (in this case, myCategory), and the log message itself.

In some case also pass metadata to the log to provide additional context for the log message. There are three types of metadata: publicMetadata, privateMetadata, and maskedMetadata. publicMetadata is metadata that is safe to expose publicly, privateMetadata is metadata that should not be exposed publicly, and maskedMetadata is metadata that should be masked in the log output. Here's an example:

```swift
logger.debug(message: "Test public metadata", metadata: [.publicMetadata(key: "TestKey", value: "TestValue")])
logger.info(message: "Test private metadata", metadata: [.privateMetadata(key: "TestKey", value: "TestValue")])
logger.debug(message: "Test equal masked metadata", metadata: [.maskedMetadata(key: "TestKey", value: "TestEqualValue")])
logger.debug(message: "Test equal masked metadata", metadata: [.maskedMetadata(key: "TestKey", value: "TestEqualValue")])
logger.debug(message: "Test different masked metadata", metadata: [.maskedMetadata(key: "TestKey", value: "TestDifferentValue")])
```

This will output the following log messages:

```
2022-04-07T18:20:17+0100 debug [ io.prism.swift.sdk.apollo ] : TestKey=TestValue Test public metadata
2022-04-07T18:20:17+0100 info [ io.prism.swift.sdk.apollo ] : TestKey=------ Test private metadata
2022-04-07T18:20:17+0100 debug [ io.prism.swift.sdk.apollo ] : TestKey={Random generated identifier 1} Test equal masked metadata
2022-04-07T18:20:17+0100 debug [ io.prism.swift.sdk.apollo ] : TestKey={Random generated identifier 1} Test equal masked metadata
2022-04-07T18:20:17+0100 debug [ io.prism.swift.sdk.apollo ] : TestKey={Random generated identifier 2} Test different masked metadata
```
