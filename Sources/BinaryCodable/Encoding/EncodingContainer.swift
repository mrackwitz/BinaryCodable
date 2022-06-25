import Foundation

protocol EncodingContainer {
    
    var data: Data { get }
    
    var dataType: DataType { get }
}

extension EncodingContainer {
    
    var dataWithLengthInformationIfRequired: Data {
        guard dataType == .variableLength else {
            return data
        }
        let data = self.data
        return data.count.variableLengthEncoding + data
    }
}
