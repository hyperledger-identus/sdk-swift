/// Log component
///
/// This components identify a part of the SDK. You can set the component and its own log level.
/// This way you can debug single parts of the SDK.
public enum LogComponent: String, Hashable {
    case apollo
    case castor
    case core
    case mercury
    case pluto
    case pollux
    case edgeAgent
}
