import Foundation

final class ValueEncoder: AbstractEncodingNode, SingleValueEncodingContainer {
    
    private var container: EncodingContainer?

    private var hasValue = false
    
    func encodeNil() throws {
        if !containsOptional {
            fatalError("Calling `encodeNil()` on `SingleValueEncodingContainer` is not supported")
        }
        assign { nil }
    }
    
    private func assign(_ encoded: () throws -> EncodingContainer?) rethrows {
        guard !hasValue else {
            fatalError("Attempt to encode multiple values in single value container")
        }
        container = try encoded()
        hasValue = true
    }
    
    func encode<T>(_ value: T) throws where T : Encodable {
        if value is AnyOptional {
            try assign {
                try EncodingNode(path: codingPath, info: userInfo, optional: true).encoding(value)
            }
        } else if let primitive = value as? EncodablePrimitive {
            // Note: This assignment also work for optionals with a value, so
            // we need to check for optionals explicitly before
            try assign {
                try wrapError(path: codingPath) {
                    try EncodedPrimitive(primitive: primitive)
                }
            }
        } else {
            try assign {
                try EncodingNode(path: codingPath, info: userInfo, optional: false).encoding(value)
            }
        }
    }
}

extension ValueEncoder: EncodingContainer {

    private var isNil: Bool { container == nil }
    
    var data: Data {
        if containsOptional {
            if isNil {
                return Data([0])
            }
            return Data([1]) + (container?.dataWithLengthInformationIfRequired ?? .empty)
        }
        return container?.data ?? .empty
    }

    var dataWithLengthInformationIfRequired: Data {
        if containsOptional {
            return data
        }
        guard dataType == .variableLength else {
            return data
        }
        return dataWithLengthInformation
    }
    
    var dataType: DataType {
        if containsOptional {
            return .variableLength
        }
        return container?.dataType ?? .byte
    }

    var isEmpty: Bool {
        container?.isEmpty ?? true
    }

    private var optionalData: Data {
        guard let container else {
            return Data([0])
        }
        return Data([1]) + container.dataWithLengthInformationIfRequired
    }

    func encodeWithKey(_ key: CodingKeyWrapper) -> Data {
        guard containsOptional else {
            return key.encode(for: container?.dataType ?? .byte) + (container?.dataWithLengthInformationIfRequired ?? .empty)
        }
        let data = optionalData
        return key.encode(for: .variableLength) + data.count.variableLengthEncoding + optionalData
    }
}
