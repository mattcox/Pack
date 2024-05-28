//
//  BinaryPack.swift
//  Pack
//
//  Created by Matt Cox on 01/02/2022.
//  Copyright © 2024 Matt Cox. All rights reserved.
//

import Foundation

/// A ``Packer`` and ``Unpacker`` that can pack and unpack binary data.
///
/// BinaryPack is intended for packing and unpacking primitive types as raw
/// 8-bit memory aligned data. For example, an `Int8` and `Int16` can be
/// packed alongside each other, with no marker indicating where one value ends
/// and the other begins. It is up to the caller to describe a consistent data
/// layout that allows values to be packed and unpacked.
///
public final class BinaryPack {
	private let state: State
	private var dataStored: Data? = nil
	private var streamStored: Stream? = nil
	private var offset: Int = 0
	private let byteOrder: ByteOrder
	
	private enum State {
		case packing
		case unpacking
	}
	
/// The user info for storing local data associated with the current pack
/// operation.
///
	public var userInfo: [PackUserInfoKey: Any] = [:]
	
/// The options used to initialize the BinaryPack object.
///
	public let options: Options
	
/// The default set of options that are used to initialize a BinaryPack
/// object, when no options are specified.
///
	public static var defaultOptions: Options = [.stringsPrependedWithSize]
	
/// BinaryPack supports a number of options that controls how data is packed
/// and unpacked.
///
/// The options are defined as an `OptionSet` so can be combined to specify
/// multiple options.
///
	public struct Options: OptionSet {
/// The corresponding value of the raw type.
///
/// A new instance initialized with `rawValue` will be equivalent to
/// this instance. For example:
///
/// ```swift
/// (Options.stringsNullTerminated == Options(rawValue: Options.stringsNullTerminated.rawValue)!)
/// // Prints "true"
/// ```
///
		public let rawValue: Int
	
/// Null terminates strings by inserting and reading an empty value at
/// the end of the string.
///
		public static let stringsNullTerminated = Options(rawValue: 1 << 0)

/// Packs and unpacks strings by storing the size of the string data as
/// an `Int32`, immediately before the string.
///
		public static let stringsPrependedWithSize = Options(rawValue: 1 << 1)
		
/// Specifies no options.
///
/// - Warning: Packing string data with no options for how to handle
/// string length could cause issues when unpacking, as the unpacker
/// will not know when to stop reading the string.
///
		public static var none = Options(rawValue: .zero)

/// Initialize a new Options object from a raw value.
///
/// A new instance initialized with `rawValue` will be equivalent to
/// this instance. For example:
///
/// ```swift
/// (Options.stringsNullTerminated == Options(rawValue: Options.stringsNullTerminated.rawValue)!)
/// // Prints "true"
/// ```
///
/// - Parameters:
///   - rawValue: The raw value for the options.
///
		public init(rawValue: Int) {
			self.rawValue = rawValue
		}
	}

/// Initialize a new BinaryPacker, writing to a `Data` object owned by the
/// packer.
///
/// The packer is initialized using default options, and data can **only**
/// be packed to this object - not unpacked.
///
	public init() {
		self.state = .packing
		self.dataStored = Data()
		self.options = BinaryPack.defaultOptions
		self.byteOrder = .system
	}

/// Initialize a new BinaryPacker, writing to a `Data` object owned by the
/// packer.
///
/// Data can **only** be packed to this object - not unpacked.
///
/// - Parameters:
///   - options: The options to initialize the BinaryPacker.
///   - byteOrder: The byte order used to pack values.
///
	public init(options: Options, byteOrder: ByteOrder = .system) {
		self.state = .packing
		self.dataStored = Data()
		self.options = options
		self.byteOrder = byteOrder
	}
	
/// Initialize a new BinaryPacker, writing to a `Data` object owned by the
/// packer.
///
/// The packer is initialized using default options, and data can **only**
/// be packed to this object - not unpacked.
///
/// - Parameters:
///   - byteOrder: The byte order used to pack values.
///
	public init(byteOrder: ByteOrder) {
		self.state = .packing
		self.dataStored = Data()
		self.options = BinaryPack.defaultOptions
		self.byteOrder = byteOrder
	}

/// Initialize a new BinaryPacker, writing to the provided `OutputStream`.
///
/// The packer is initialized using default options, and data can **only**
/// be packed to this object - not unpacked.
///
/// - Parameters:
///   - stream: The stream to pack the data into.
///
	public init(writingTo stream: OutputStream) {
		self.state = .packing
		self.streamStored = stream
		self.options = BinaryPack.defaultOptions
		self.byteOrder = .system
	}

/// Initialize a new BinaryPacker, writing to the provided `OutputStream`.
///
/// Data can **only** be packed to this object - not unpacked.
///
/// - Parameters:
///   - stream: The stream to pack the data into.
///   - options: The options to initialize the BinaryPacker.
///   - byteOrder: The byte order used to pack values.
///
	public init(writingTo stream: OutputStream, options: Options, byteOrder: ByteOrder = .system) {
		self.state = .packing
		self.streamStored = stream
		self.options = options
		self.byteOrder = byteOrder
	}
	
/// Initialize a new BinaryPacker, writing to the provided `OutputStream`.
///
/// The packer is initialized using default options, and data can **only**
/// be packed to this object - not unpacked.
///
/// - Parameters:
///   - stream: The stream to pack the data into.
///   - byteOrder: The byte order used to pack values.
///
	public init(writingTo stream: OutputStream, byteOrder: ByteOrder) {
		self.state = .packing
		self.streamStored = stream
		self.options = BinaryPack.defaultOptions
		self.byteOrder = byteOrder
	}
	
/// Initialize a new BinaryPacker, reading data from the provided `Data`
/// object.
///
/// The unpacker is initialized using default options, and data can **only**
/// be unpacked from this object - not packed.
///
/// - Parameters:
///   - data: The `Data` object to unpack data from.
///
	public init(from data: Data) {
		self.state = .unpacking
		self.dataStored = data
		self.options = BinaryPack.defaultOptions
		self.byteOrder = .system
	}

/// Initialize a new BinaryPacker, reading data from the provided `Data`
/// object.
///
/// Data can **only** be unpacked from this object - not packed.
///
/// - Parameters:
///   - data: The `Data` object to unpack data from.
///   - options: The options to initialize the BinaryPacker.
///   - byteOrder: The byte order used to unpack values.
///
	public init(from data: Data, options: Options, byteOrder: ByteOrder = .system) {
		self.state = .unpacking
		self.dataStored = data
		self.options = options
		self.byteOrder = byteOrder
	}
	
/// Initialize a new BinaryPacker, reading data from the provided `Data`
/// object.
///
/// The unpacker is initialized using default options, and data can **only**
/// be unpacked from this object - not packed.
///
/// - Parameters:
///   - data: The `Data` object to unpack data from.
///   - byteOrder: The byte order used to unpack values.
///
	public init(from data: Data, byteOrder: ByteOrder) {
		self.state = .unpacking
		self.dataStored = data
		self.options = BinaryPack.defaultOptions
		self.byteOrder = byteOrder
	}

/// Initialize a new Packer, reading from the provided `InputStream`.
///
/// The unpacker is initialized using default options, and data can **only**
/// be unpacked from this object - not packed.
///
/// - Parameters:
///   - stream: The stream to unpack data from.
///
	public init(readingFrom stream: InputStream) {
		self.state = .unpacking
		self.streamStored = stream
		self.options = BinaryPack.defaultOptions
		self.byteOrder = .system
	}

/// Initialize a new Packer, reading from the provided `InputStream`.
///
/// Data can **only** be unpacked from this object - not packed.
///
/// - Parameters:
///   - stream: The stream to unpack data from.
///   - options: The options to initialize the BinaryPacker.
///   - byteOrder: The byte order used to unpack values.
///
	public init(readingFrom stream: InputStream, options: Options, byteOrder: ByteOrder = .system) {
		self.state = .unpacking
		self.streamStored = stream
		self.options = options
		self.byteOrder = byteOrder
	}
	
/// Initialize a new Packer, reading from the provided `InputStream`.
///
/// The unpacker is initialized using default options, and data can **only**
/// be unpacked from this object - not packed.
///
/// - Parameters:
///   - stream: The stream to unpack data from.
///   - options: The options to initialize the BinaryPacker.
///   - byteOrder: The byte order used to unpack values.
///
	public init(readingFrom stream: InputStream, byteOrder: ByteOrder) {
		self.state = .unpacking
		self.streamStored = stream
		self.options = BinaryPack.defaultOptions
		self.byteOrder = byteOrder
	}
}

extension BinaryPack: Packer {
/// Indicates if the BinaryPacker is currently packing.
///
	public var isPacking: Bool {
		get {
			self.state == .packing
		}
	}

	public var data: Data {
		get throws {
			guard self.isPacking else {
				throw PackError.notPacking
			}
			
			guard let data = dataStored else {
				throw PackError.invalidPackingDestination
			}
			
			return data
		}
	}
	
/// Decodes the provided type into `Data`.
///
/// If the byte order used to initialize the BinaryPack is different to the
/// system byte order, then the bytes in the `Data` object will be reversed.
///
/// - Parameters:
///   - value: The value to decode.
///
/// - Returns: A `Data` object containing the bytes from the provided
/// type.
///
/// - Throws: ``PackError`` if the type cannot be decoded.
///
	private func decodeBytes<T: BinaryInteger>(from value: T) throws -> Data {
		// The size of the object being packed in bytes.
		//
		let bytesCount = MemoryLayout<T>.size
		
		// Shift the bits to grab each 8 bits of data. To prevent the UInt8 from
		// from going out of bounds when the larger bit shifted value is packed
		// into it, it is AND with a bit mask representing the smallest 8 bits.
		//
		var bitMask = T.zero
		for i in 0..<8 {
			bitMask |= 1 << i
		}
		
		var bytes = Data()
		for i in (0..<bytesCount).reversed() {
			var byte = (value >> (i * 8)) & bitMask
			let byteData = Data(bytes: &byte, count: MemoryLayout<UInt8>.size)
			bytes.append(byteData)
		}
		
		if bytes.count != bytesCount {
			throw PackError.failure(reason: "Unable to decode bytes for writing")
		}
		
		// If the system byte order is different to the byte order used to
		// initialize the packer, then swap the bits.
		//
		ByteOrder.system.swap(&bytes, to: self.byteOrder)
		
		return bytes
	}

/// Decodes the `Float` into a `Data` object.
///
/// If the byte order used to initialize the BinaryPack is different to the
/// system byte order, then the bytes in the `Data` object will be reversed.
///
/// - Parameters:
///   - value: The `Float` to decode.
///
/// - Returns: The `Data` object containing the bytes from the provided
/// `Float`.
///
/// - Throws: ``PackError`` if the type cannot be decoded.
///
	private func decodeBytes(from value: Float) throws -> Data {
		try decodeBytes(from: value.bitPattern)
	}

/// Decodes the `Double` into a `Data` object.
///
/// If the byte order used to initialize the BinaryPack is different to the
/// system byte order, then the bytes in the `Data` object will be reversed.
///
/// - Parameters:
///   - value: The `Double` to decode.
///
/// - Returns: The `Data` object containing the bytes from the provided
/// `Double`.
///
/// - Throws: ``PackError`` if the type cannot be decoded.
///
	private func decodeBytes(from value: Double) throws -> Data {
		try decodeBytes(from: value.bitPattern)
	}
	
/// Writes the `Data` object into the output - either a `Data` object, or an
/// `OutputStream`.
///
/// - Parameters:
///   - bytes: The `Data` object to write.
///
/// - Throws: `PackError` or a stream error if the data cannot be written.
///
	private func writeBytes(_ bytes: Data) throws {
		guard self.isPacking else {
			throw PackError.notPacking
		}
		
		if bytes.isEmpty {
			return
		}
		
		// If the data object is not nil, then write the data there. Otherwise,
		// attempt to write it to the output stream.
		//
		if dataStored != nil {
			dataStored?.append(bytes)
		}
		else if let stream = streamStored as? OutputStream {
			let bytesWritten = try bytes.withUnsafeBytes { rawBufferPointer -> Int in
				let pointer = rawBufferPointer.bindMemory(to: UInt8.self)
				guard let baseAddress = pointer.baseAddress else {
					throw PackError.unknown
				}
				return stream.write(baseAddress, maxLength: bytes.count)
			}
			
			if bytesWritten == 0 {
				// If no bytes were written, then there is not enough space in
				// the buffer, so throw an error.
				//
				throw PackError.shortBuffer
			}
			else if bytesWritten == -1 {
				// If an error occurred, then throw the error.
				//
				if stream.streamStatus == .notOpen {
					throw PackError.failure(reason: "Stream is not open")
				}
				else if stream.streamStatus == .closed {
					throw PackError.failure(reason: "Stream has been closed")
				}
				
				let error = stream.streamError ?? PackError.unknown
				throw error
			}
			else if bytesWritten != bytes.count {
				// This shouldn't really happen, but if the bytes written is
				// different to the size of the data being written, then an
				// "unknown" error is thrown.
				//
				throw PackError.unknown
			}
		}
		else {
			// If neither the stream of the output data is valid, then throw
			// an error.
			//
			throw PackError.invalidPackingDestination
		}
	}
	
	public func pack(_ value: Bool) throws {
		// When packing a boolean, it's packed as a UInt8, with the first bit
		// set to 0 or 1, depending on the boolean state.
		//
		let bytes = Data(repeating: (value ? 1 : 0), count: 1)
		try writeBytes(bytes)
	}
	
	public func pack(_ value: Double) throws {
		let bytes = try decodeBytes(from: value)
		try writeBytes(bytes)
	}
	
	public func pack(_ value: Float) throws {
		let bytes = try decodeBytes(from: value)
		try writeBytes(bytes)
	}
	
	public func pack(_ value: Int) throws {
		let bytes = try decodeBytes(from: value)
		try writeBytes(bytes)
	}
	
	public func pack(_ value: Int8) throws {
		let bytes = try decodeBytes(from: value)
		try writeBytes(bytes)
	}
	
	public func pack(_ value: Int16) throws {
		let bytes = try decodeBytes(from: value)
		try writeBytes(bytes)
	}
	
	public func pack(_ value: Int32) throws {
		let bytes = try decodeBytes(from: value)
		try writeBytes(bytes)
	}
	
	public func pack(_ value: Int64) throws {
		let bytes = try decodeBytes(from: value)
		try writeBytes(bytes)
	}
	
	public func pack(_ value: UInt) throws {
		let bytes = try decodeBytes(from: value)
		try writeBytes(bytes)
	}
	
	public func pack(_ value: UInt8) throws {
		let bytes = Data(repeating: value, count: 1)
		try writeBytes(bytes)
	}
	
	public func pack(_ value: UInt16) throws {
		let bytes = try decodeBytes(from: value)
		try writeBytes(bytes)
	}
	
	public func pack(_ value: UInt32) throws {
		let bytes = try decodeBytes(from: value)
		try writeBytes(bytes)
	}
	
	public func pack(_ value: UInt64) throws {
		let bytes = try decodeBytes(from: value)
		try writeBytes(bytes)
	}
	
/// Pack a `String` type value into the packer, with a specified encoding.
///
/// Regardless of the byte order specified when initializing the BinaryPack
/// object, the byte order of the `String` will not be modified. If a
/// specific byte order is required, that variant of the string encoding
/// should be used, for example `utf16BigEndian` or `utf16LittleEndian`.
///
/// - Warning: Care should be taken when packing a `String`, to ensure the
/// Encoding of the string will not change. For example, packing a string
/// using `ascii` will store characters in 8 bits, whereas packing the
/// string as `utf32` may result in up to 32 bits per character. To ensure
/// packed strings can always be unpacked, a consistent encoding should be
/// used.
///
/// - Parameters:
///   - value: The `String` to pack.
///   - encoding: The string encoding used to encode the characters in the
///   string into memory.
///
/// - Throws: ``PackError`` if the packer is currently not packing values.
///
	public func pack(_ value: String, using encoding: String.Encoding = .utf8) throws {
		guard self.isPacking else {
			throw PackError.notPacking
		}
	
		// If the string is being null terminated, only a specific subset of
		// encodings are supported.
		//
		if options.contains(.stringsNullTerminated) {
			if encoding != .ascii && encoding != .utf8 {
				throw PackError.unsupportedEncoding
			}
		}
		
		// Get the string as data.
		//
		guard let stringData = value.data(using: encoding) else {
			throw PackError.failure(reason: "Unable to convert string into Data using specified encoding.")
		}
		
		// If the options specify the size of the string data should be written
		// first, then write it out.
		//
		let stringDataCount: Int32 = Int32(stringData.count)
		if self.options.contains(.stringsPrependedWithSize) {
			try self.pack(stringDataCount)
		}
		
		// Write the bytes into the output.
		//
		try writeBytes(stringData)
		
		// If the string should be null terminated, add the null terminators to
		// the end.
		//
		if self.options.contains(.stringsNullTerminated) {
			try self.pack(UInt8.zero)
		}
	}

/// Pack bytes stored in a `Data` object into the packer.
///
/// Regardless of the byte order specified when initializing the BinaryPack
/// object, the byte order of the `Data` will not be modified.
///
/// - Parameters:
///   - value: The `Data` object containing the bytes to pack.
///
/// - Throws: ``PackError`` if the packer is currently not packing values.
///
	public func pack(_ data: Data) throws {
		try writeBytes(data)
	}
	
	public func pack(_ packable: Packable) throws {
		guard self.isPacking else {
			throw PackError.notPacking
		}
	
		var packer = self as Packer
		try packable.pack(to: &packer)
	}
}

extension BinaryPack: Unpacker {
/// Indicates if the BinaryPacker is currently unpacking.
///
	public var isUnpacking: Bool {
		get {
			self.state == .unpacking
		}
	}

/// Encodes the bytes from the provided `Data` object into the specified
/// type.
///
/// If the byte order used to initialize the BinaryPack is different to the
/// system byte order, then the bytes in the `Data` object will be reversed.
///
/// - Parameters:
///   - bytes: The bytes to encode into the type.
///   - type: The type of object to encode the data into.
///
/// - Returns: A type initialized with the bytes from the `Data` object.
///
/// - Throws: ``PackError`` if the type cannot be encoded.
///
	private func encodeBytes<T: BinaryInteger>(_ bytes: Data, into type: T.Type) throws -> T {
		// If the system byte order is different to the byte order used to
		// initialize the unpacker, then swap the bits.
		//
		var data = bytes
		self.byteOrder.swap(&data, to: .system)
		
		// The size of the object being unpacked in bytes.
		//
		let bytesCount = MemoryLayout<T>.size
		if bytesCount != bytes.count {
			throw PackError.failure(reason: "Unable to encode bytes for reading")
		}
		
		// Read each byte from the input data, shift left and OR with the
		// previous byte.
		//
		// This is less than ideal and can likely be optimized. Essentially
		// the type cannot be cast from a UInt8 to the target type, as the
		// value will be cast - not the bits. Therefore, we need to pack the
		// bits one by one from each byte into the bits of the target object.
		// TODO: Try and optimize away the nested loop with a conditional.
		//
		var value = T.zero
		var shift = bytesCount * 8
		for byteIndex in (0..<bytesCount) {
			let byte = data[byteIndex]
			for bitIndex in (0..<8).reversed() {
				shift -= 1
				value |= T(((byte >> bitIndex) & 0x01) != 0x0 ? 0x01 : 0x0) << shift
			}
		}
		
		return value
	}

/// Encodes the bytes from the provided `Data` object into a `Double`.
///
/// If the byte order used to initialize the BinaryPack is different to the
/// system byte order, then the bytes in the `Data` object will be reversed
/// before converting into a `Double`.
///
/// - Parameters:
///   - bytes: The bytes to encode into a `Double`.
///   - type: The type of object to encode the data into.
///
/// - Returns: A `Double` value initialized with the bytes from the `Data`
/// object.
///
/// - Throws: ``PackError`` if the type cannot be encoded.
///
	private func encodeBytes(_ bytes: Data, into: Double.Type) throws -> Double {
		let bitPattern = try encodeBytes(bytes, into: UInt64.self)
		return Double(bitPattern: bitPattern)
	}

/// Encodes the bytes from the provided `Data` object into a `Float`.
///
/// If the byte order used to initialize the BinaryPack is different to the
/// system byte order, then the bytes in the `Data` object will be reversed
/// before converting into a `Float`.
///
/// - Parameters:
///   - bytes: The bytes to encode into a `Float`.
///   - type: The type of object to encode the data into.
///
/// - Returns: A `Float` value initialized with the bytes from the `Data`
/// object.
///
/// - Throws: ``PackError`` if the type cannot be encoded.
///
	private func encodeBytes(_ bytes: Data, into: Float.Type) throws -> Float {
		let bitPattern = try encodeBytes(bytes, into: UInt32.self)
		return Float(bitPattern: bitPattern)
	}

/// Reads in the input for the specified number of bytes, and returns them
/// as a `Data` object.
///
/// - Parameters:
///   - count: The number of bytes to read.
///
/// - Returns: A `Data` object containing the specified number of bytes
/// from the input source.
///
/// - Throws: `PackError` or a stream error if the data cannot be read.
///
	private func readBytes(count: Int) throws -> Data {
		guard self.isUnpacking else {
			throw PackError.notUnpacking
		}
		
		var bytes = Data()
		if let data = dataStored {
			// Check if there is enough memory left in the data source to read
			// the provided object.
			//
			if data.count < (self.offset + count) {
				throw PackError.shortBuffer
			}
		
			// Read the data from the stored data source, offsetting the read
			// position forward at each step.
			//
			if count == 1 {
				bytes.append(data[self.offset])
				self.offset += 1
			}
			else {
				bytes.append(data.subdata(in: self.offset..<(self.offset + count)))
				self.offset += count
			}
		}
		else if let stream = streamStored as? InputStream {
			// Read the data from the input stream. As the length of the stream
			// is unknown, if this fails at any point, then we assume the end of
			// the stream has been reached.
			//
			if count == 1 {
				var value: UInt8 = 0
				
				let bytesRead = stream.read(&value, maxLength: count)
				if bytesRead == 0 {
					// If no bytes were read, then there is not enough space in
					// the buffer, so throw an error.
					//
					throw PackError.shortBuffer
				}
				else if bytesRead == -1 {
					// If an error occurred, then throw the error.
					//
					if stream.streamStatus == .notOpen {
						throw PackError.failure(reason: "Stream is not open")
					}
					else if stream.streamStatus == .closed {
						throw PackError.failure(reason: "Stream has been closed")
					}
					
					let error = stream.streamError ?? PackError.unknown
					throw error
				}
				else if bytesRead != count {
					// This shouldn't really happen, but if the bytes read is
					// different to the size of the data being read, then an
					// "unknown" error is thrown.
					//
					throw PackError.unknown
				}
				
				bytes.append(value)
			}
			else {
				var buffer = ContiguousArray<UInt8>(unsafeUninitializedCapacity: count) { pointer, initialized in
					for i in 0..<count {
						pointer[i] = .zero
					}
					initialized = count
				}
				
				let bytesRead = withUnsafeMutablePointer(to: &buffer[0]) { pointer -> Int in
					return stream.read(pointer, maxLength: count)
				}

				if bytesRead == 0 {
					// If no bytes were read, then there is not enough space in
					// the buffer, so throw an error.
					//
					throw PackError.shortBuffer
				}
				else if bytesRead == -1 {
					// If an error occurred, then throw the error.
					//
					if stream.streamStatus == .notOpen {
						throw PackError.failure(reason: "Stream is not open")
					}
					else if stream.streamStatus == .closed {
						throw PackError.failure(reason: "Stream has been closed")
					}
					
					let error = stream.streamError ?? PackError.unknown
					throw error
				}
				else if bytesRead != count {
					// This shouldn't really happen, but if the bytes read is
					// different to the size of the data being read, then an
					// "unknown" error is thrown.
					//
					throw PackError.unknown
				}
				
				bytes.append(contentsOf: buffer)
			}
		}
		else {
			// If neither the stream of the input data is valid, then throw
			// an error.
			//
			throw PackError.invalidUnpackingSource
		}
		
		return bytes
	}
	
	public func offset(by count: UInt) throws {
		if dataStored != nil {
			self.offset += Int(count)
		}
		else if streamStored != nil {
			_ = try readBytes(count: Int(count))
		}
		else {
			throw PackError.invalidUnpackingSource
		}
	}

	public func unpack(_ type: Bool.Type) throws -> Bool {
		let bytes = try readBytes(count: MemoryLayout<Bool>.size)
		guard let byte = bytes.first else {
			throw PackError.failure()
		}
		return byte != 0
	}
	
	public func unpack(_ type: Double.Type) throws -> Double {
		let bytes = try readBytes(count: MemoryLayout<Double>.size)
		return try encodeBytes(bytes, into: Double.self)
	}

	public func unpack(_ type: Float.Type) throws -> Float {
		let bytes = try readBytes(count: MemoryLayout<Float>.size)
		return try encodeBytes(bytes, into: Float.self)
	}

	public func unpack(_ type: Int.Type) throws -> Int {
		let bytes = try readBytes(count: MemoryLayout<Int>.size)
		return try encodeBytes(bytes, into: Int.self)
	}

	public func unpack(_ type: Int8.Type) throws -> Int8 {
		let bytes = try readBytes(count: MemoryLayout<Int8>.size)
		return try encodeBytes(bytes, into: Int8.self)
	}

	public func unpack(_ type: Int16.Type) throws -> Int16 {
		let bytes = try readBytes(count: MemoryLayout<Int16>.size)
		return try encodeBytes(bytes, into: Int16.self)
	}

	public func unpack(_ type: Int32.Type) throws -> Int32 {
		let bytes = try readBytes(count: MemoryLayout<Int32>.size)
		return try encodeBytes(bytes, into: Int32.self)
	}

	public func unpack(_ type: Int64.Type) throws -> Int64 {
		let bytes = try readBytes(count: MemoryLayout<Int64>.size)
		return try encodeBytes(bytes, into: Int64.self)
	}

	public func unpack(_ type: UInt.Type) throws -> UInt {
		let bytes = try readBytes(count: MemoryLayout<UInt>.size)
		return try encodeBytes(bytes, into: UInt.self)
	}

	public func unpack(_ type: UInt8.Type) throws -> UInt8 {
		let bytes = try readBytes(count: MemoryLayout<UInt8>.size)
		return try encodeBytes(bytes, into: UInt8.self)
	}

	public func unpack(_ type: UInt16.Type) throws -> UInt16 {
		let bytes = try readBytes(count: MemoryLayout<UInt16>.size)
		return try encodeBytes(bytes, into: UInt16.self)
	}

	public func unpack(_ type: UInt32.Type) throws -> UInt32 {
		let bytes = try readBytes(count: MemoryLayout<UInt32>.size)
		return try encodeBytes(bytes, into: UInt32.self)
	}

	public func unpack(_ type: UInt64.Type) throws -> UInt64 {
		let bytes = try readBytes(count: MemoryLayout<UInt64>.size)
		return try encodeBytes(bytes, into: UInt64.self)
	}
	
/// Unpack a `String` type value from the data source, packed with the
/// specified encoding.
///
/// Regardless of the byte order specified when initializing the BinaryPack
/// object, the byte order of the `String` will not be modified. If a
/// specific byte order is required, that variant of the string encoding
/// should be used, for example `utf16BigEndian` or `utf16LittleEndian`.
///
/// - Warning: Care should be taken when unpacking a `String`, to ensure the
/// Encoding of the string is the same as when it was packed. For example,
/// packing a string using `ascii` will store characters in 8 bits, whereas
/// packing the string as `utf32` may result in up to 32 bits per character.
/// To ensure packed strings can always be unpacked, a consistent encoding
/// should be used.
///
/// - Parameters:
///   - type: The type of object to unpack.
///   - encoding: The string encoding that the string was encoded with when
///   packing.
///
/// - Throws: ``PackError`` if the unpacker is currently not unpacking
/// values, or if the end of the input source is reached.
///
	public func unpack(_ type: String.Type, using encoding: String.Encoding = .utf8) throws -> String {
		guard self.isUnpacking else {
			throw PackError.notUnpacking
		}
		
		// If the string is null terminated, only specific encodings are
		// supported.
		//
		if options.contains(.stringsNullTerminated) {
			if encoding != .ascii && encoding != .utf8 {
				throw PackError.unsupportedEncoding
			}
		}
		
		// If the options specify the size of the string data is written first,
		// then read it in.
		//
		var stringData = Data()
		if options.contains(.stringsPrependedWithSize) {
			let stringDataCount = try self.unpack(Int32.self)
			if stringDataCount > 0 {
				// Read the string for the specified number of bytes.
				//
				stringData = try readBytes(count: Int(stringDataCount))
				
				// If the string is null terminated, read the null terminator and
				// discard.
				//
				if options.contains(.stringsNullTerminated) {
					_ = try self.unpack(UInt8.self)
				}
			}
		}
		else if options.contains(.stringsNullTerminated) {
			// Continue reading until we reach a null terminator, or the end of
			// the input source is reached.
			//
			while(true) {
				// Read one byte at a time.
				//
				let data = try readBytes(count: 1)
				if let byte = data.first {
					if byte == .zero {
						break
					}
					
					stringData.append(byte)
				}
				else {
					throw PackError.unknown
				}
			}
		}
		else {
			// Continue reading until the end of the input source is reached.
			//
			do {
				while(true) {
					// Read one byte at a time.
					//
					let data = try readBytes(count: 1)
					if let byte = data.first {
						stringData.append(byte)
					}
					else {
						throw PackError.unknown
					}
				}
			}
			catch PackError.shortBuffer {
				// The end of the input source has been reached.
			}
			catch {
				throw error
			}
		}
		
		// Convert the string data into a string.
		//
		guard let string = String(data: stringData, encoding: encoding) else {
			throw PackError.failure()
		}
		
		return string
	}

/// Unpack bytes from the data source, without interpreting the data as a
/// specific type. The number of bytes to read can be specified.
///
/// Regardless of the byte order specified when initializing the BinaryPack
/// object, the byte order of the `Data` will not be modified.
///
/// - Parameters:
///   - type: The type of object to unpack.
///   - size: The number of bytes to read from the data source.
///
/// - Throws: ``PackError`` if the unpacker is currently not unpacking
/// values, or if the end of the input source is reached.
///
	public func unpack(_ type: Data.Type, size: Int) throws -> Data {
		try readBytes(count: size)
	}
	
	public func unpack<T: Unpackable>(_ type: T.Type) throws -> T {
		guard self.isUnpacking else {
			throw PackError.notUnpacking
		}
	
		var unpacker = self as Unpacker
		return try T(from: &unpacker)
	}
}
