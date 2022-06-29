import Foundation

protocol EncodingContainer {
    
    var data: Data { get }
    
    var dataType: DataType { get }

    var isNil: Bool { get }

    func encodeWithKey(_ key: CodingKeyWrapper, proto: Bool) -> Data
}

extension EncodingContainer {
    
    var dataWithLengthInformationIfRequired: Data {
        guard dataType == .variableLength else {
            return data
        }
        return dataWithLengthInformation
    }

    var dataWithLengthInformation: Data {
        let data = self.data
        return data.count.variableLengthEncoding + data
    }


    func encodeWithKey(_ key: CodingKeyWrapper, proto: Bool) -> Data {
        key.encode(for: dataType, proto: proto) + dataWithLengthInformationIfRequired
    }
}

extension EncodingContainer {

    var isNil: Bool {
        // Default implementation for most containers
        false
    }
}
