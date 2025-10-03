import Combine
import CryptoKit
import Foundation
import Logging

/// SDKLogger.
///
/// Mainly used to log in the SDK, this component makes a few of funcionalities available such as:
/// - Different Logging Levels
/// - Identify the logging with essential data (Date, Component, Message, Metadata)
/// - Ability to hide sensible metadata in private or masked
/// - Can output to a the Apple console, a log file or debug console
///
/// Internally SDKLogger uses swift-log.
///
/// Examples:
///
/// ````
/// let logger = Logger(category: .apollo)
/// // Will always show the value of the metadata
/// logger.debug(message: "Test public metadata", metadata: [.publicMetadata(key: "TestKey", value: "TestValue")])
///
/// // Will never show the value of the metadata, it will be replaced by "-------"
/// logger.info(message: "Test private metadata", metadata: [.privateMetadata(key: "TestKey", value: "TestValue")])
///
/// // Will never show this metadata value, instead it will be replaced by an identifiable hash.
/// // Every time this value and the key are the same during the session. The hash will be the same.
/// logger.debug(message: "Test equal masked metadata", metadata: [.maskedMetadata(key: "TestKey", value: "TestEqualValue")])
/// logger.debug(message: "Test equal masked metadata", metadata: [.maskedMetadata(key: "TestKey", value: "TestEqualValue")])
/// logger.debug(message: "Test different masked metadata", metadata: [.maskedMetadata(key: "TestKey", value: "TestDifferentValue")])
///
/// output:
/// 22022-04-07T18:20:17+0100 debug [ io.prism.swift.sdk.apollo ] : TestKey=TestValue Test public metadata
/// 32022-04-07T18:20:17+0100 info [ io.prism.swift.sdk.apollo ] : TestKey=------ Test private metadata
/// 42022-04-07T18:20:17+0100 debug [ io.prism.swift.sdk.apollo ] : TestKey={Random generated identifier 1} Test equal masked metadata
/// 52022-04-07T18:20:17+0100 debug [ io.prism.swift.sdk.apollo ] : TestKey={Random generated identifier 1} Test equal masked metadata
/// 62022-04-07T18:20:17+0100 debug [ io.prism.swift.sdk.apollo ] : TestKey={Random generated identifier 2} Test different masked metadata
/// ````

private let METADATA_PRIVACY_STR = "------"

// MARK: Prism Logger

/// The log level.
///
/// Log levels are ordered by their severity, with `.debug` being the least severe and
/// `.error` being the most severe. You can also pick `.none` for no logging.
/// `.info` is the default log level
public enum LogLevel: Int {
    /// Appropriate for messages that contain information normally of use only when
    /// debugging a program.
    case debug

    /// Appropriate for informational messages.
    case info

    /// Appropriate for conditions that are not error conditions, but that may require
    /// special handling.
    case notice

    /// Appropriate for messages that are not error conditions, but more severe than
    /// `.notice`.
    case warning

    /// Appropriate for error conditions.
    case error

    /// For no logging
    case none
}

public struct SDKLogger{
    public static var logLevels = [String: LogLevel]()
    private static let hashingLog = UUID().uuidString
    private let logLevel: LogLevel

    public enum Metadata {
        /// Public metadata is completely visible in the logs
        case publicMetadata(key: String, value: String)
        /// Private metadata is replaced by the ``METADATA_PRIVACY_STR``
        case privateMetadata(key: String, value: String)
        /// Private metadata is replaced by the ``METADATA_PRIVACY_STR``
        case privateMetadataByLevel(key: String, value: String, level: LogLevel)
        /// Masked metadata is replaced by an sha256
        case maskedMetadata(key: String, value: String)
        /// Masked metadata is replaced by an sha256
        case maskedMetadataByLevel(key: String, value: String, level: LogLevel)

        fileprivate var key: String {
            switch self {
            case let .publicMetadata(key, _),
                 let .privateMetadata(key, _),
                 let .privateMetadataByLevel(key, _, _),
                 let .maskedMetadata(key, _),
                 let .maskedMetadataByLevel(key, _, _):
                return key
            }
        }

        fileprivate func getValue(for logLevel: LogLevel) -> String {
            switch self {
            case let .publicMetadata(_, value):
                return value
            case .privateMetadata:
                return METADATA_PRIVACY_STR
            case let .privateMetadataByLevel(_, value, level):
                return logLevel.rawValue <= level.rawValue ? value : METADATA_PRIVACY_STR
            case let .maskedMetadata(_, value):
                let sha256 = SHA256
                    .hash(data: Data((SDKLogger.hashingLog + value).utf8))
                    .compactMap {
                        String(format: "%02x", $0)
                    }.joined()
                return sha256
            case let .maskedMetadataByLevel(_, value, level):
                guard logLevel.rawValue > level.rawValue else {
                    return value
                }

                let sha256 = SHA256
                    .hash(data: Data((SDKLogger.hashingLog + value).utf8))
                    .compactMap {
                        String(format: "%02x", $0)
                    }.joined()
                return sha256
            }
        }
    }

    private let logger: Logger

    public init<
        LogComponent: RawRepresentable & Hashable
    >(
        category: LogComponent,
        handler: ((String) -> LogHandler)? = nil
    ) where LogComponent.RawValue == String {
        handler.map { LoggingSystem.bootstrap($0) }
        var logger = Logger(label: "[ io.prism.swift.sdk.\(category.rawValue) ]")
        logLevel = SDKLogger.logLevels.first {
            $0.key == category.rawValue
        }?.value ?? .info
        logger.logLevel = logLevel.getLoggerLevel()
        self.logger = logger
    }
}

// MARK: Prism Logger public methods

public extension SDKLogger {
    /// Logs debug level message and metadata
    /// - Parameters:
    ///   - message: String message
    ///   - metadata: Private/Public/Masked metadata
    func debug(message: String, metadata: [Metadata] = []) {
        guard logLevel != .none else { return }
        logger.debug("\(message)", metadata: metadata.loggerMetadata(logLevel: logLevel))
    }

    /// Logs info level message and metadata
    /// - Parameters:
    ///   - message: String message
    ///   - metadata: Private/Public/Masked metadata
    func info(message: String, metadata: [Metadata] = []) {
        guard logLevel != .none else { return }
        logger.info("\(message)", metadata: metadata.loggerMetadata(logLevel: logLevel))
    }

    /// Logs notice level message and metadata
    /// - Parameters:
    ///   - message: String message
    ///   - metadata: Private/Public/Masked metadata
    func notice(message: String, metadata: [Metadata] = []) {
        guard logLevel != .none else { return }
        logger.notice("\(message)", metadata: metadata.loggerMetadata(logLevel: logLevel))
    }

    /// Logs warning level message and metadata
    /// - Parameters:
    ///   - message: String message
    ///   - metadata: Private/Public/Masked metadata
    func warning(message: String, metadata: [Metadata] = []) {
        guard logLevel != .none else { return }
        logger.warning("⚠️ \(message)", metadata: metadata.loggerMetadata(logLevel: logLevel))
    }

    /// Logs error level message and metadata
    /// - Parameters:
    ///   - message: String message
    ///   - metadata: Private/Public/Masked metadata
    func error(message: String, metadata: [Metadata] = []) {
        guard logLevel != .none else { return }
        logger.error("🛑 \(message)", metadata: metadata.loggerMetadata(logLevel: logLevel))
    }

    /// Logs error level message and metadata
    /// - Parameters:
    ///   - error: ``Error``
    ///   - metadata: Private/Public/Masked metadata
    func error(error: Error, metadata: [Metadata] = []) {
        guard logLevel != .none else { return }
        if
            let localized = error as? LocalizedError,
            let message = localized.errorDescription
        {
            logger.error(
                "🛑 \(message)",
                metadata: metadata.loggerMetadata(logLevel: logLevel)
            )
        } else {
            logger.error(
                "🛑 \(error.localizedDescription)",
                metadata: metadata.loggerMetadata(logLevel: logLevel)
            )
        }
    }
}

// MARK: Combine observer helper

public extension Publisher {
    func log(logger: SDKLogger) -> AnyPublisher<Self.Output, Self.Failure> {
        handleEvents(receiveSubscription: { _ in
            logger.debug(message: "subscribed")
        }, receiveOutput: {
            logger.debug(message: "received", metadata: [
                .maskedMetadataByLevel(key: "object", value: "\($0)", level: .debug)
            ])
        }, receiveCompletion: {
            switch $0 {
            case .finished:
                logger.debug(message: "finished")
            case let .failure(error):
                logger.error(message: "finished with error", metadata: [
                    .publicMetadata(key: "Error", value: error.localizedDescription)
                ])
            }
        }, receiveCancel: {
            logger.debug(message: "cancelled")
        }, receiveRequest: { _ in
            logger.debug(message: "received demand")
        })
        .eraseToAnyPublisher()
    }
}

private extension Array where Element == SDKLogger.Metadata {
    func loggerMetadata(logLevel: LogLevel) -> Logger.Metadata {
        reduce([String: Logger.MetadataValue]()) {
            var dic = $0
            dic[$1.key] = Logger.MetadataValue.string($1.getValue(for: logLevel))
            return dic
        }
    }
}

private extension LogLevel {
    func getLoggerLevel() -> Logger.Level {
        switch self {
        case .debug:
            return .debug
        case .info:
            return .info
        case .notice:
            return .notice
        case .warning:
            return .warning
        case .error:
            return .error
        case .none:
            return .debug
        }
    }
}
