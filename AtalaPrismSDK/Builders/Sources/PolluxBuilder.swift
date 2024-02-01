import Domain
import Pollux

public struct PolluxBuilder {
    private let pluto: Pluto

    public init(pluto: Pluto) {
        self.pluto = pluto
    }

    public func build() -> [PolluxPlugin] {
        [AnoncredsPlugin(), JWTPlugin()]
    }
}
