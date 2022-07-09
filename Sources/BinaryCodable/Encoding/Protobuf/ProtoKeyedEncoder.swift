import Foundation

final class ProtoKeyedEncoder<Key>: AbstractEncodingNode, KeyedEncodingContainerProtocol where Key: CodingKey {

    var content = [IntKeyWrapper : NonNilEncodingContainer]()

    func assign(_ value: NonNilEncodingContainer, to key: CodingKey) throws {
        let wrapped = try IntKeyWrapper(key)
        assign(value, to: wrapped)
    }

    func assign(_ value: NonNilEncodingContainer, to key: IntKeyWrapper) {
        content[key] = value
    }

    func encodeNil(forKey key: Key) throws {
        throw BinaryEncodingError.nilValuesNotSupported    }

    func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        let container: NonNilEncodingContainer
        if let primitive = value as? EncodablePrimitive {
            container = try EncodedPrimitive(protobuf: primitive, excludeDefaults: true)
        } else if value is AnyDictionary {
            container = try ProtoDictEncodingNode(path: codingPath, info: userInfo).encoding(value)
        } else {
            container = try ProtoEncodingNode(path: codingPath, info: userInfo).encoding(value)
        }
        try assign(container, to: key)
    }

    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        do {
            let wrapped = try IntKeyWrapper(key)
            let container = ProtoKeyedEncoder<NestedKey>(path: codingPath + [key], info: userInfo)
            assign(container, to: wrapped)
            return KeyedEncodingContainer(container)
        } catch {
            let container = ProtoKeyedThrowingEncoder<NestedKey>(error: error as! BinaryEncodingError,
                                                                 path: codingPath + [key],
                                                                 info: userInfo)
            return KeyedEncodingContainer(container)
        }

    }

    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        do {
            let wrapped = try IntKeyWrapper(key)
            let container = ProtoUnkeyedEncoder(path: codingPath + [key], info: userInfo)
            assign(container, to: wrapped)
            return container
        } catch {
            let container = ProtoUnkeyedThrowingEncoder(error: error as! BinaryEncodingError, path: codingPath, info: userInfo)
            return container
        }
    }

    func superEncoder() -> Encoder {
        ProtoThrowingNode(error: .superNotSupported, path: codingPath, info: userInfo)
    }

    func superEncoder(forKey key: Key) -> Encoder {
        ProtoThrowingNode(error: .superNotSupported, path: codingPath, info: userInfo)
    }
}

extension ProtoKeyedEncoder: NonNilEncodingContainer {

    private var nonEmptyValues: [(key: IntKeyWrapper, value: NonNilEncodingContainer)] {
        content.filter { !$0.value.isEmpty }
    }

    private var sortedKeysIfNeeded: [(key: IntKeyWrapper, value: NonNilEncodingContainer)] {
        guard sortKeysDuringEncoding else {
            return nonEmptyValues.map { $0 }
        }
        return nonEmptyValues.sorted { $0.key < $1.key }
    }

    var data: Data {
        sortedKeysIfNeeded.map { key, value -> Data in
            value.encodeWithKey(key)
        }.reduce(Data(), +)
    }

    var dataType: DataType {
        .variableLength
    }

    var isEmpty: Bool {
        !content.values.contains { !$0.isEmpty }
    }
}