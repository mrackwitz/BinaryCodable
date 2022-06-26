import Foundation

final class UnkeyedEncoder: AbstractEncodingNode, UnkeyedEncodingContainer {
    
    var count: Int {
        content.count + nilIndices.count
    }
    
    private var content = [EncodingContainer]()
    
    private var nilIndices = Set<Int>()
    
    @discardableResult
    private func assign<T>(_ encoded: () throws -> T) rethrows -> T where T: EncodingContainer {
        let value = try encoded()
        content.append(value)
        return value
    }
    
    func encodeNil() {
        nilIndices.insert(count)
    }
    
    func encode<T>(_ value: T) throws where T : Encodable {
        if let primitive = value as? EncodablePrimitive {
            try assign {
                try EncodedPrimitive(primitive: primitive)
            }
            return
        }
        if let optional = value as? AnyOptional, optional.isNil {
            encodeNil()
            return
        }
        try assign {
            try EncodingNode(codingPath: codingPath, userInfo: userInfo).encoding(value)
        }
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        let container = assign {
            KeyedEncoder<NestedKey>(codingPath: codingPath, userInfo: userInfo)
        }
        return KeyedEncodingContainer(container)
    }
    
    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        assign {
            UnkeyedEncoder(codingPath: codingPath, userInfo: userInfo)
        }
    }
    
    func superEncoder() -> Encoder {
        assign {
            EncodingNode(codingPath: codingPath, userInfo: userInfo)
        }
    }
}

extension UnkeyedEncoder: EncodingContainer {
    
    private var nilIndicesData: Data {
        let count = nilIndices.count
        return count.variableLengthEncoding + nilIndices.sorted().map { $0.variableLengthEncoding }.joined()
    }
    
    private var contentData: FlattenSequence<[Data]> {
        content.map { $0.dataWithLengthInformationIfRequired }.joined()
    }
    
    var data: Data {
        nilIndicesData + contentData
    }
    
    var dataType: DataType {
        .variableLength
    }
}

extension UnkeyedEncoder: CustomStringConvertible {
    
    var description: String {
        "Unkeyed\n" + content.map { "\($0)".indented()
        }.joined(separator: "\n").indented()
    }
}
