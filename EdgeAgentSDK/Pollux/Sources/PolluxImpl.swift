import Combine
import Core
import Domain

public struct PolluxImpl {
    let pluto: Pluto
    let castor: Castor
    let presentationExchangeParsers: [SubmissionDescriptorFormatParser]
    let logger: SDKLogger

    public init(
        castor: Castor,
        pluto: Pluto,
        presentationExchangeParsers: [SubmissionDescriptorFormatParser],
        logger: SDKLogger = SDKLogger(category: LogComponent.pollux)
    ) {
        self.pluto = pluto
        self.castor = castor
        self.presentationExchangeParsers = presentationExchangeParsers
        self.logger = logger
    }

    public init(
        castor: Castor,
        pluto: Pluto,
        logger: SDKLogger = SDKLogger(category: LogComponent.pollux)
    ) {
        self.init(
            castor: castor,
            pluto: pluto,
            presentationExchangeParsers: [
                JWTPresentationExchangeParser(verifier: .init(castor: castor)),
                JWTVCPresentationExchangeParser(verifier: .init(castor: castor)),
                JWTVPPresentationExchangeParser(verifier: .init(castor: castor)),
                SDJWTPresentationExchangeParser(verifier: .init(castor: castor, logger: logger))
            ],
            logger: logger
        )
    }
}
