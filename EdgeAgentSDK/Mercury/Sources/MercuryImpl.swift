import Combine
import Core
import DIDCommSwift
import Domain
import Foundation

public struct MercuryImpl {
    let session: SessionManager
    let secretsStream: AnyPublisher<[Domain.Secret], Error>
    let castor: Castor
    let logger: SDKLogger

    public init(
        session: URLSession = .shared,
        timeout: TimeInterval = 999,
        secretsStream: AnyPublisher<[Domain.Secret], Error>,
        castor: Castor
    ) {
        let logger = SDKLogger(category: LogComponent.mercury)
        self.logger = logger
        self.session = SessionManager(session: session, timeout: timeout)
        self.secretsStream = secretsStream
        self.castor = castor
    }

    func getDidcomm() -> DIDComm {
        let didResolver = DIDCommDIDResolverWrapper(castor: castor, logger: logger)
        let secretsResolver = DIDCommSecretsResolverWrapper(
            secretsStream: secretsStream,
            castor: castor,
            logger: logger
        )
        return DIDComm(
            didResolver: didResolver,
            secretResolver: secretsResolver
        )
    }
}
