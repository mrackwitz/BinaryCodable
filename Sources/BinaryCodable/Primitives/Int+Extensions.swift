import Foundation

extension Int: VariableLengthCodable {
    
    var variableLengthEncoding: Data {
        Int64(self).variableLengthEncoding
    }
    
    static func readVariableLengthEncoded(from data: Data) throws -> (value: Int, consumedBytes: Int) {
        let (intValue, consumedBytes) = try Int64.readVariableLengthEncoded(from: data)
        guard let value = Int(exactly: intValue) else {
            throw BinaryEncodingError.variableLengthEncodedIntegerOutOfRange
        }
        return (value: value, consumedBytes: consumedBytes)
    }
}
