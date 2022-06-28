import Foundation

extension Int32: EncodablePrimitive {
    
    func data() -> Data {
        variableLengthEncoding
    }
    
    static var dataType: DataType {
        .variableLengthInteger
    }
}

extension Int32: DecodablePrimitive {

    init(decodeFrom data: Data) throws {
        self = try Int32.readVariableLengthEncoded(from: data)
    }
}

extension Int32: VariableLengthCodable {
    
    var variableLengthEncoding: Data {
        UInt32(bitPattern: self).variableLengthEncoding
    }
    
    init(fromVarint data: Data) throws {
        let value = try UInt32(fromVarint: data)
        self = Int32(bitPattern: value)
    }
}

extension Int32: HostIndependentRepresentable {

    /**
     Convert the value to a host-independent (little endian) format.
     */
    var hostIndependentRepresentation: UInt32 {
        CFSwapInt32HostToLittle(.init(bitPattern: self))
    }

    /**
     Create an `Int32` value from its host-independent (little endian) representation.
     - Parameter value: The host-independent representation
     */
    init(fromHostIndependentRepresentation value: UInt32) {
        self.init(bitPattern: CFSwapInt32LittleToHost(value))
    }
}
