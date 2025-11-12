import Foundation

extension ClaimElement: Encodable {
    /// An error indicating that a `ClaimElement` could not be encoded because its key
    /// could not be represented as a valid `CodingKey`.
    ///
    /// This is typically thrown when attempting to construct a `DynamicCodingKey`
    /// from the `ClaimElement`'s `key` string fails (for example, when the key is
    /// invalid for the current encoding context).
    ///
    /// Usage:
    /// - Thrown from `encode(to:)` and related helper methods when a key cannot be
    ///   converted into `DynamicCodingKey`.
    /// - Catch this error to diagnose malformed or unsupported keys during JSON or
    ///   other keyed encoding processes.
    ///
    /// See also:
    /// - `DynamicCodingKey` for details on how keys are constructed for encoding.
    /// - `ClaimElement` encoding paths that rely on valid keyed containers.
    public struct InvalidKeyEncodingError: Error {}
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        guard let key = DynamicCodingKey(stringValue: key) else { throw InvalidKeyEncodingError() }
        switch element {
        case .codable(let obj):
            try container.encode(obj, forKey: key)
        case .element(let element):
            try container.encode(element, forKey: key)
        case .array(let elements):
            var nested = container.nestedUnkeyedContainer(forKey: key)
            try encodeArrayElements(container: &nested, elements: elements)
        case .object(let elements):
            var nested: KeyedEncodingContainer<DynamicCodingKey>
            if key.stringValue.isEmpty {
                nested = container
            } else {
                nested = container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: key)
            }

            try encodeObjectElement(container: &nested, elements: elements)
        }
    }

    private func encodeArrayElements(container: inout UnkeyedEncodingContainer, elements: [ClaimElement]) throws {
        try elements.forEach {
            switch $0.element {
            case .codable(let obj):
                try container.encode(obj)
            case .element(let element):
                try container.encode(element)
            case .array(let elements):
                var nested = container.nestedUnkeyedContainer()
                try encodeArrayElements(container: &nested, elements: elements)
            case .object(let elements):
                var nested = container.nestedContainer(keyedBy: DynamicCodingKey.self)
                try encodeObjectElement(container: &nested, elements: elements)
            }
        }
    }

    private func encodeObjectElement(container: inout KeyedEncodingContainer<DynamicCodingKey>, elements: [ClaimElement]) throws {
        try elements.forEach {
            guard let key = DynamicCodingKey(stringValue: $0.key) else { throw InvalidKeyEncodingError() }
            switch $0.element {
            case .codable(let obj):
                try container.encode(obj, forKey: key)
            case .element(let element):
                try container.encode(element, forKey: key)
            case .array(let elements):
                var nested = container.nestedUnkeyedContainer(forKey: key)
                try encodeArrayElements(container: &nested, elements: elements)
            case .object(let elements):
                var nested = container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: key)
                try encodeObjectElement(container: &nested, elements: elements)
            }
        }
    }
}

struct DynamicCodingKey: CodingKey {
    var stringValue: String
    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    var intValue: Int?
    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}
