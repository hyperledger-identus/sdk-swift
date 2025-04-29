import Combine
import CoreData
import Domain

extension CDMessageDAO: MessageStore {
    func addMessages(messages: [(Message, Message.Direction)]) -> AnyPublisher<Void, Error> {
        messages
            .publisher
            .flatMap { (message, direction) in
                self.fetchDIDPair(from: message.from, to: message.to)
                    .map {
                        (message, direction, $0)
                    }
            }
            .collect()
            .eraseToAnyPublisher()
            .flatMap { messages in
                self.batchUpdateOrCreate(
                    messages.map(\.0.id),
                    context: writeContext
                ) { id, cdobj, _ in
                    guard let domainObjs = messages.first(where: { $0.0.id == id }) else {
                        return
                    }
                    try cdobj.fromDomain(msg: domainObjs.0, direction: domainObjs.1, pair: domainObjs.2)
                }
            }
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func addMessage(msg: Message, direction: Message.Direction) -> AnyPublisher<Void, Error> {
        return pairDAO
            .fetchController(
                predicate: NSPredicate(
                    format: "(holderDID.did == %@) OR (holderDID.did == %@) OR (did == %@) OR (did == %@)",
                    msg.from?.string ?? "",
                    msg.to?.string ?? "",
                    msg.from?.string ?? "",
                    msg.to?.string ?? ""
                ),
                context: writeContext
            )
            .first()
            .map { $0.first }
            .flatMap { pair in
                self.batchUpdateOrCreate(
                    [msg.id],
                    context: writeContext
                ) { id, cdobj, _ in
                    try cdobj.fromDomain(msg: msg, direction: direction, pair: pair)
                }
            }
            .map { _ in }
            .eraseToAnyPublisher()
    }

    func removeMessage(id: String) -> AnyPublisher<Void, Error> {
        deleteByIDsPublisher([id], context: writeContext)
    }

    func removeAll() -> AnyPublisher<Void, Error> {
        deleteAllPublisher(context: writeContext)
    }

    private func fetchDIDPair(from: DID?, to: DID?) -> AnyPublisher<CDDIDPair?, Error> {
        pairDAO
            .fetchController(
                predicate: NSPredicate(
                    format: "(holderDID.did == %@) OR (holderDID.did == %@) OR (did == %@) OR (did == %@)",
                    from?.string ?? "",
                    to?.string ?? "",
                    from?.string ?? "",
                    to?.string ?? ""
                ),
                context: writeContext
            )
            .first()
            .map { $0.first }
            .eraseToAnyPublisher()
    }
}

private extension CDMessage {
    func fromDomain(msg: Message, direction: Message.Direction, pair: CDDIDPair?) throws {
        self.messageId = msg.id
        self.from = msg.from?.string
        self.to = msg.to?.string
        self.type = msg.piuri
        self.dataJson = try JSONEncoder().encode(CodableMessage(message: msg))
        self.createdTime = msg.createdTime
        self.pair = pair
        self.direction = direction.rawValue
    }
}
