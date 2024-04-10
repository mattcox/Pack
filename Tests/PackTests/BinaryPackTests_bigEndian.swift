//
//  BinaryPackTests_bigEndian.swift
//  PackTests
//
//  Created by Matt Cox on 13/02/2022.
//  Copyright © 2024 Matt Cox. All rights reserved.
//

import XCTest
@testable import Pack
import Foundation

final class BinaryPackTests_bigEndian: XCTestCase {
	private let byteOrder: ByteOrder = .bigEndian

	private func packer(options: BinaryPack.Options = BinaryPack.defaultOptions) -> BinaryPack {
		BinaryPack(options: options, byteOrder: self.byteOrder)
	}
	
	private func packer(destination: OutputStream, options: BinaryPack.Options = BinaryPack.defaultOptions) -> BinaryPack {
		BinaryPack(writingTo: destination, options: options, byteOrder: self.byteOrder)
	}
	
	private func unpacker(source: Data, options: BinaryPack.Options = BinaryPack.defaultOptions) -> BinaryPack {
		BinaryPack(from: source, options: options, byteOrder: self.byteOrder)
	}
	
	private func unpacker(source: InputStream, options: BinaryPack.Options = BinaryPack.defaultOptions) -> BinaryPack {
		BinaryPack(readingFrom: source, options: options, byteOrder: self.byteOrder)
	}
	
	private func withOutputStream(size: Int = 1024, perform: (OutputStream) throws -> Void) rethrows -> Data {
		var buffer = ContiguousArray<UInt8>(unsafeUninitializedCapacity: size) { pointer, initialized in
			for i in 0..<size {
				pointer[i] = .zero
			}
			initialized = size
		}
		
		let outputStream = OutputStream(toBuffer: &buffer[0], capacity: size)
		outputStream.open()
		defer {
			outputStream.close()
		}
		
		try perform(outputStream)
		
		var data = Data()
		data.append(contentsOf: buffer)
		return data
	}
	
	private func withInputStream(wrapping data: Data, perform: (InputStream) throws -> Void) rethrows {
		let inputStream = InputStream(data: data)
		inputStream.open()
		defer {
			inputStream.close()
		}
		
		try perform(inputStream)
	}
	
	private func noisyData(_ byteCount: Int) -> Data {
		var data = Data()
		for _ in 0..<byteCount {
			data.append(UInt8.random(in: UInt8.min...UInt8.max))
		}
		return data
	}

/// Tests packing a Bool into a data object.
///
	func test_packAndUnpack_toData_bigEndian_Bool() throws {
		let value: Bool = true
	
		let packer = self.packer()
		try packer.pack(value)
	
		let data = try packer.data
		XCTAssertTrue(data.count == MemoryLayout<Bool>.size, "The size of the packed data is larger than expected.")
	
		let unpacker = self.unpacker(source: data)
		let result = try unpacker.unpack(type(of: value).self)

		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a Bool into a stream.
///
	func test_packAndUnpack_toStream_bigEndian_Bool() throws {
		let value: Bool = true
		
		let data = try withOutputStream {
			let packer = self.packer(destination: $0)
			try packer.pack(value)
		}

		var result: Bool = false
		try withInputStream(wrapping: data) {
			let unpacker = self.unpacker(source: $0)
			result = try unpacker.unpack(type(of: value).self)
		}
		
		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a Double into a data object.
///
	func test_packAndUnpack_toData_bigEndian_Double() throws {
		let value = Double.random(in: 0...Double.greatestFiniteMagnitude)

		let packer = self.packer()
		try packer.pack(value)
	
		let data = try packer.data
		XCTAssertTrue(data.count == MemoryLayout<Double>.size, "The size of the packed data is larger than expected.")
	
		let unpacker = self.unpacker(source: data)
		let result = try unpacker.unpack(type(of: value).self)

		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a Double into a stream.
///
	func test_packAndUnpack_toStream_bigEndian_Double() throws {
		let value = Double.random(in: 0...Double.greatestFiniteMagnitude)
		
		let data = try withOutputStream {
			let packer = self.packer(destination: $0)
			try packer.pack(value)
		}

		var result: Double = .zero
		try withInputStream(wrapping: data) {
			let unpacker = self.unpacker(source: $0)
			result = try unpacker.unpack(type(of: value).self)
		}
		
		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a Float into a data object.
///
	func test_packAndUnpack_toData_bigEndian_Float() throws {
		let value = Float.random(in: 0...Float.greatestFiniteMagnitude)
	
		let packer = self.packer()
		try packer.pack(value)
		
		let data = try packer.data
		XCTAssertTrue(data.count == MemoryLayout<Float>.size, "The size of the packed data is larger than expected.")
	
		let unpacker = self.unpacker(source: data)
		let result = try unpacker.unpack(type(of: value).self)

		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a Float into a stream.
///
	func test_packAndUnpack_toStream_bigEndian_Float() throws {
		let value = Float.random(in: 0...Float.greatestFiniteMagnitude)
		
		let data = try withOutputStream {
			let packer = self.packer(destination: $0)
			try packer.pack(value)
		}

		var result: Float = .zero
		try withInputStream(wrapping: data) {
			let unpacker = self.unpacker(source: $0)
			result = try unpacker.unpack(type(of: value).self)
		}
		
		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing an Int into a data object.
///
	func test_packAndUnpack_toData_bigEndian_Int() throws {
		let value = Int.random(in: Int.min...Int.max)
	
		let packer = self.packer()
		try packer.pack(value)
	
		let data = try packer.data
		XCTAssertTrue(data.count == MemoryLayout<Int>.size, "The size of the packed data is larger than expected.")
	
		let unpacker = self.unpacker(source: data)
		let result = try unpacker.unpack(type(of: value).self)

		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing an Int into a stream.
///
	func test_packAndUnpack_toStream_bigEndian_Int() throws {
		let value = Int.random(in: Int.min...Int.max)
		
		let data = try withOutputStream {
			let packer = self.packer(destination: $0)
			try packer.pack(value)
		}

		var result: Int = .zero
		try withInputStream(wrapping: data) {
			let unpacker = self.unpacker(source: $0)
			result = try unpacker.unpack(type(of: value).self)
		}
		
		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}

/// Tests packing an Int8 into a data object.
///
	func test_packAndUnpack_toData_bigEndian_Int8() throws {
		let value = Int8.random(in: Int8.min...Int8.max)
	
		let packer = self.packer()
		try packer.pack(value)
	
		let data = try packer.data
		XCTAssertTrue(data.count == MemoryLayout<Int8>.size, "The size of the packed data is larger than expected.")
	
		let unpacker = self.unpacker(source: data)
		let result = try unpacker.unpack(type(of: value).self)

		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing an Int8 into a stream.
///
	func test_packAndUnpack_toStream_bigEndian_Int8() throws {
		let value = Int8.random(in: Int8.min...Int8.max)
		
		let data = try withOutputStream {
			let packer = self.packer(destination: $0)
			try packer.pack(value)
		}

		var result: Int8 = .zero
		try withInputStream(wrapping: data) {
			let unpacker = self.unpacker(source: $0)
			result = try unpacker.unpack(type(of: value).self)
		}
		
		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing an Int16 into a data object.
///
	func test_packAndUnpack_toData_bigEndian_Int16() throws {
		let value = Int16.random(in: Int16.min...Int16.max)
	
		let packer = self.packer()
		try packer.pack(value)
	
		let data = try packer.data
		XCTAssertTrue(data.count == MemoryLayout<Int16>.size, "The size of the packed data is larger than expected.")
	
		let unpacker = self.unpacker(source: data)
		let result = try unpacker.unpack(type(of: value).self)

		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing an Int16 into a stream.
///
	func test_packAndUnpack_toStream_bigEndian_Int16() throws {
		let value = Int16.random(in: Int16.min...Int16.max)
		
		let data = try withOutputStream {
			let packer = self.packer(destination: $0)
			try packer.pack(value)
		}

		var result: Int16 = .zero
		try withInputStream(wrapping: data) {
			let unpacker = self.unpacker(source: $0)
			result = try unpacker.unpack(type(of: value).self)
		}
		
		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing an Int32 into a data object.
///
	func test_packAndUnpack_toData_bigEndian_Int32() throws {
		let value = Int32.random(in: Int32.min...Int32.max)
	
		let packer = self.packer()
		try packer.pack(value)
	
		let data = try packer.data
		XCTAssertTrue(data.count == MemoryLayout<Int32>.size, "The size of the packed data is larger than expected.")
	
		let unpacker = self.unpacker(source: data)
		let result = try unpacker.unpack(type(of: value).self)

		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing an Int32 into a stream.
///
	func test_packAndUnpack_toStream_bigEndian_Int32() throws {
		let value = Int32.random(in: Int32.min...Int32.max)
		
		let data = try withOutputStream {
			let packer = self.packer(destination: $0)
			try packer.pack(value)
		}

		var result: Int32 = .zero
		try withInputStream(wrapping: data) {
			let unpacker = self.unpacker(source: $0)
			result = try unpacker.unpack(type(of: value).self)
		}
		
		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing an Int64 into a data object.
///
	func test_packAndUnpack_toData_bigEndian_Int64() throws {
		let value = Int64.random(in: Int64.min...Int64.max)
	
		let packer = self.packer()
		try packer.pack(value)
	
		let data = try packer.data
		XCTAssertTrue(data.count == MemoryLayout<Int64>.size, "The size of the packed data is larger than expected.")
	
		let unpacker = self.unpacker(source: data)
		let result = try unpacker.unpack(type(of: value).self)

		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing an Int64 into a stream.
///
	func test_packAndUnpack_toStream_bigEndian_Int64() throws {
		let value = Int64.random(in: Int64.min...Int64.max)
		
		let data = try withOutputStream {
			let packer = self.packer(destination: $0)
			try packer.pack(value)
		}

		var result: Int64 = .zero
		try withInputStream(wrapping: data) {
			let unpacker = self.unpacker(source: $0)
			result = try unpacker.unpack(type(of: value).self)
		}
		
		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a UInt into a data object.
///
	func test_packAndUnpack_toData_bigEndian_UInt() throws {
		let value = UInt.random(in: UInt.min...UInt.max)
	
		let packer = self.packer()
		try packer.pack(value)
	
		let data = try packer.data
		XCTAssertTrue(data.count == MemoryLayout<UInt>.size, "The size of the packed data is larger than expected.")
	
		let unpacker = self.unpacker(source: data)
		let result = try unpacker.unpack(type(of: value).self)

		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a UInt into a stream.
///
	func test_packAndUnpack_toStream_bigEndian_UInt() throws {
		let value = UInt.random(in: UInt.min...UInt.max)
		
		let data = try withOutputStream {
			let packer = self.packer(destination: $0)
			try packer.pack(value)
		}

		var result: UInt = .zero
		try withInputStream(wrapping: data) {
			let unpacker = self.unpacker(source: $0)
			result = try unpacker.unpack(type(of: value).self)
		}
		
		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}

/// Tests packing a UInt8 into a data object.
///
	func test_packAndUnpack_toData_bigEndian_UInt8() throws {
		let value = UInt8.random(in: UInt8.min...UInt8.max)
	
		let packer = self.packer()
		try packer.pack(value)
	
		let data = try packer.data
		XCTAssertTrue(data.count == MemoryLayout<UInt8>.size, "The size of the packed data is larger than expected.")
	
		let unpacker = self.unpacker(source: data)
		let result = try unpacker.unpack(type(of: value).self)

		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a UInt8 into a stream.
///
	func test_packAndUnpack_toStream_bigEndian_UInt8() throws {
		let value = UInt8.random(in: UInt8.min...UInt8.max)
		
		let data = try withOutputStream {
			let packer = self.packer(destination: $0)
			try packer.pack(value)
		}

		var result: UInt8 = .zero
		try withInputStream(wrapping: data) {
			let unpacker = self.unpacker(source: $0)
			result = try unpacker.unpack(type(of: value).self)
		}
		
		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a UInt16 into a data object.
///
	func test_packAndUnpack_toData_bigEndian_UInt16() throws {
		let value = UInt16.random(in: UInt16.min...UInt16.max)
	
		let packer = self.packer()
		try packer.pack(value)
	
		let data = try packer.data
		XCTAssertTrue(data.count == MemoryLayout<UInt16>.size, "The size of the packed data is larger than expected.")
	
		let unpacker = self.unpacker(source: data)
		let result = try unpacker.unpack(type(of: value).self)

		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a UInt16 into a stream.
///
	func test_packAndUnpack_toStream_bigEndian_UInt16() throws {
		let value = UInt16.random(in: UInt16.min...UInt16.max)
		
		let data = try withOutputStream {
			let packer = self.packer(destination: $0)
			try packer.pack(value)
		}

		var result: UInt16 = .zero
		try withInputStream(wrapping: data) {
			let unpacker = self.unpacker(source: $0)
			result = try unpacker.unpack(type(of: value).self)
		}
		
		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a UInt32 into a data object.
///
	func test_packAndUnpack_toData_bigEndian_UInt32() throws {
		let value = UInt32.random(in: UInt32.min...UInt32.max)
	
		let packer = self.packer()
		try packer.pack(value)
	
		let data = try packer.data
		XCTAssertTrue(data.count == MemoryLayout<UInt32>.size, "The size of the packed data is larger than expected.")
	
		let unpacker = self.unpacker(source: data)
		let result = try unpacker.unpack(type(of: value).self)

		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a UInt32 into a stream.
///
	func test_packAndUnpack_toStream_bigEndian_UInt32() throws {
		let value = UInt32.random(in: UInt32.min...UInt32.max)
		
		let data = try withOutputStream {
			let packer = self.packer(destination: $0)
			try packer.pack(value)
		}

		var result: UInt32 = .zero
		try withInputStream(wrapping: data) {
			let unpacker = self.unpacker(source: $0)
			result = try unpacker.unpack(type(of: value).self)
		}
		
		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a UInt64 into a data object.
///
	func test_packAndUnpack_toData_bigEndian_UInt64() throws {
		let value = UInt64.random(in: UInt64.min...UInt64.max)
	
		let packer = self.packer()
		try packer.pack(value)
	
		let data = try packer.data
		XCTAssertTrue(data.count == MemoryLayout<UInt64>.size, "The size of the packed data is larger than expected.")
	
		let unpacker = self.unpacker(source: data)
		let result = try unpacker.unpack(type(of: value).self)

		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a UInt64 into a stream.
///
	func test_packAndUnpack_toStream_bigEndian_UInt64() throws {
		let value = UInt64.random(in: UInt64.min...UInt64.max)
		
		let data = try withOutputStream {
			let packer = self.packer(destination: $0)
			try packer.pack(value)
		}

		var result: UInt64 = .zero
		try withInputStream(wrapping: data) {
			let unpacker = self.unpacker(source: $0)
			result = try unpacker.unpack(type(of: value).self)
		}
		
		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}

/// Tests packing a Data object into a data object.
///
	func test_packAndUnpack_toData_bigEndian_Data() throws {
		let value = self.noisyData(512)
	
		let packer = self.packer()
		try packer.pack(value)
	
		let data = try packer.data
		XCTAssertTrue(data.count == value.count, "The size of the packed data is larger than expected.")
	
		let unpacker = self.unpacker(source: data)
		let result = try unpacker.unpack(type(of: value).self, size: value.count)

		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a Data object into a stream.
///
	func test_packAndUnpack_toStream_bigEndian_Data() throws {
		let value = self.noisyData(512)
		
		let data = try withOutputStream(size: 512) {
			let packer = self.packer(destination: $0)
			try packer.pack(value)
		}

		var result: Data = Data()
		try withInputStream(wrapping: data) {
			let unpacker = self.unpacker(source: $0)
			result = try unpacker.unpack(type(of: value).self, size: value.count)
		}
		
		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}

/// Tests packing a String object into a data object, with ascii encoding
/// and the string prepended with size.
///
	func test_packAndUnpack_toData_bigEndian_String_ascii_prependedWithSize() throws {
		let value = "I am a test string!"
	
		let packer = self.packer(options: .stringsPrependedWithSize)
		try packer.pack(value, using: .ascii)
	
		let data = try packer.data
	
		let unpacker = self.unpacker(source: data, options: .stringsPrependedWithSize)
		let result = try unpacker.unpack(type(of: value).self, using: .ascii)

		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a String object into a stream, with ascii encoding.
///
	func test_packAndUnpack_toStream_bigEndian_String_ascii_prependedWithSize() throws {
		let value = "I am a test string!"
		
		let data = try withOutputStream(size: 512) {
			let packer = self.packer(destination: $0, options: .stringsPrependedWithSize)
			try packer.pack(value, using: .ascii)
		}

		var result: String = ""
		try withInputStream(wrapping: data) {
			let unpacker = self.unpacker(source: $0, options: .stringsPrependedWithSize)
			result = try unpacker.unpack(type(of: value).self, using: .ascii)
		}
		
		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}

/// Tests packing a String object into a data object, with ascii encoding
/// and the string null terminated.
///
	func test_packAndUnpack_toData_bigEndian_String_ascii_nullTerminated() throws {
		let value = "I am a test string!"
	
		let packer = self.packer(options: .stringsNullTerminated)
		try packer.pack(value, using: .ascii)
	
		let data = try packer.data
	
		let unpacker = self.unpacker(source: data, options: .stringsNullTerminated)
		let result = try unpacker.unpack(type(of: value).self, using: .ascii)

		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a String object into a stream, with ascii encoding.
///
	func test_packAndUnpack_toStream_bigEndian_String_ascii_nullTerminated() throws {
		let value = "I am a test string!"
		
		let data = try withOutputStream(size: 512) {
			let packer = self.packer(destination: $0, options: .stringsNullTerminated)
			try packer.pack(value, using: .ascii)
		}

		var result: String = ""
		try withInputStream(wrapping: data) {
			let unpacker = self.unpacker(source: $0, options: .stringsNullTerminated)
			result = try unpacker.unpack(type(of: value).self, using: .ascii)
		}
		
		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a String object into a data object, with utf8 encoding
/// and the string prepended with size.
///
	func test_packAndUnpack_toData_bigEndian_String_utf8_prependedWithSize() throws {
		let value = "I am a test string! 仮 🌙 Ok"
	
		let packer = self.packer(options: .stringsPrependedWithSize)
		try packer.pack(value, using: .utf8)
	
		let data = try packer.data
	
		let unpacker = self.unpacker(source: data, options: .stringsPrependedWithSize)
		let result = try unpacker.unpack(type(of: value).self, using: .utf8)

		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a String object into a stream, with utf8 encoding.
///
	func test_packAndUnpack_toStream_bigEndian_String_utf8_prependedWithSize() throws {
		let value = "I am a test string! 仮 🌙 Ok"
		
		let data = try withOutputStream(size: 512) {
			let packer = self.packer(destination: $0, options: .stringsPrependedWithSize)
			try packer.pack(value, using: .utf8)
		}

		var result: String = ""
		try withInputStream(wrapping: data) {
			let unpacker = self.unpacker(source: $0, options: .stringsPrependedWithSize)
			result = try unpacker.unpack(type(of: value).self, using: .utf8)
		}
		
		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}

/// Tests packing a String object into a data object, with utf8 encoding
/// and the string null terminated.
///
	func test_packAndUnpack_toData_bigEndian_String_utf8_nullTerminated() throws {
		let value = "I am a test string! 仮 🌙 Ok"
	
		let packer = self.packer(options: .stringsNullTerminated)
		try packer.pack(value, using: .utf8)
	
		let data = try packer.data
	
		let unpacker = self.unpacker(source: data, options: .stringsNullTerminated)
		let result = try unpacker.unpack(type(of: value).self, using: .utf8)

		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a String object into a stream, with utf8 encoding.
///
	func test_packAndUnpack_toStream_bigEndian_String_utf8_nullTerminated() throws {
		let value = "I am a test string! 仮 🌙 Ok"
		
		let data = try withOutputStream(size: 512) {
			let packer = self.packer(destination: $0, options: .stringsNullTerminated)
			try packer.pack(value, using: .utf8)
		}

		var result: String = ""
		try withInputStream(wrapping: data) {
			let unpacker = self.unpacker(source: $0, options: .stringsNullTerminated)
			result = try unpacker.unpack(type(of: value).self, using: .utf8)
		}
		
		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}

/// Tests packing a String object into a data object, with utf16 encoding
/// and the string prepended with size.
///
	func test_packAndUnpack_toData_bigEndian_String_utf16_prependedWithSize() throws {
		let value = "I am a test string! 仮 🌙 Ok"
	
		let packer = self.packer(options: .stringsPrependedWithSize)
		try packer.pack(value, using: .utf16)
	
		let data = try packer.data
	
		let unpacker = self.unpacker(source: data, options: .stringsPrependedWithSize)
		let result = try unpacker.unpack(type(of: value).self, using: .utf16)

		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a String object into a stream, with utf16 encoding.
///
	func test_packAndUnpack_toStream_bigEndian_String_utf16_prependedWithSize() throws {
		let value = "I am a test string! 仮 🌙 Ok"
		
		let data = try withOutputStream(size: 512) {
			let packer = self.packer(destination: $0, options: .stringsPrependedWithSize)
			try packer.pack(value, using: .utf16)
		}

		var result: String = ""
		try withInputStream(wrapping: data) {
			let unpacker = self.unpacker(source: $0, options: .stringsPrependedWithSize)
			result = try unpacker.unpack(type(of: value).self, using: .utf16)
		}
		
		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a String object into a data object, with utf16BigEndian
/// encoding and the string prepended with size.
///
	func test_packAndUnpack_toData_bigEndian_String_utf16BigEndian_prependedWithSize() throws {
		let value = "I am a test string! 仮 🌙 Ok"
	
		let packer = self.packer(options: .stringsPrependedWithSize)
		try packer.pack(value, using: .utf16BigEndian)
	
		let data = try packer.data
	
		let unpacker = self.unpacker(source: data, options: .stringsPrependedWithSize)
		let result = try unpacker.unpack(type(of: value).self, using: .utf16BigEndian)

		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a String object into a stream, with utf16BigEndian encoding.
///
	func test_packAndUnpack_toStream_bigEndian_String_utf16BigEndian_prependedWithSize() throws {
		let value = "I am a test string! 仮 🌙 Ok"
		
		let data = try withOutputStream(size: 512) {
			let packer = self.packer(destination: $0, options: .stringsPrependedWithSize)
			try packer.pack(value, using: .utf16BigEndian)
		}

		var result: String = ""
		try withInputStream(wrapping: data) {
			let unpacker = self.unpacker(source: $0, options: .stringsPrependedWithSize)
			result = try unpacker.unpack(type(of: value).self, using: .utf16BigEndian)
		}
		
		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a String object into a data object, with utf16LittleEndian
/// encoding and the string prepended with size.
///
	func test_packAndUnpack_toData_bigEndian_String_utf16LittleEndian_prependedWithSize() throws {
		let value = "I am a test string! 仮 🌙 Ok"
	
		let packer = self.packer(options: .stringsPrependedWithSize)
		try packer.pack(value, using: .utf16LittleEndian)
	
		let data = try packer.data
	
		let unpacker = self.unpacker(source: data, options: .stringsPrependedWithSize)
		let result = try unpacker.unpack(type(of: value).self, using: .utf16LittleEndian)

		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a String object into a stream, with utf16LittleEndian encoding.
///
	func test_packAndUnpack_toStream_bigEndian_String_utf16LittleEndian_prependedWithSize() throws {
		let value = "I am a test string! 仮 🌙 Ok"
		
		let data = try withOutputStream(size: 512) {
			let packer = self.packer(destination: $0, options: .stringsPrependedWithSize)
			try packer.pack(value, using: .utf16LittleEndian)
		}

		var result: String = ""
		try withInputStream(wrapping: data) {
			let unpacker = self.unpacker(source: $0, options: .stringsPrependedWithSize)
			result = try unpacker.unpack(type(of: value).self, using: .utf16LittleEndian)
		}
		
		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a String object into a data object, with utf32 encoding
/// and the string prepended with size.
///
	func test_packAndUnpack_toData_bigEndian_String_utf32_prependedWithSize() throws {
		let value = "I am a test string! 仮 🌙 Ok"
	
		let packer = self.packer(options: .stringsPrependedWithSize)
		try packer.pack(value, using: .utf32)
	
		let data = try packer.data
	
		let unpacker = self.unpacker(source: data, options: .stringsPrependedWithSize)
		let result = try unpacker.unpack(type(of: value).self, using: .utf32)

		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a String object into a stream, with utf32 encoding.
///
	func test_packAndUnpack_toStream_bigEndian_String_utf32_prependedWithSize() throws {
		let value = "I am a test string! 仮 🌙 Ok"
		
		let data = try withOutputStream(size: 512) {
			let packer = self.packer(destination: $0, options: .stringsPrependedWithSize)
			try packer.pack(value, using: .utf32)
		}

		var result: String = ""
		try withInputStream(wrapping: data) {
			let unpacker = self.unpacker(source: $0, options: .stringsPrependedWithSize)
			result = try unpacker.unpack(type(of: value).self, using: .utf32)
		}
		
		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a String object into a data object, with utf32BigEndian
/// encoding and the string prepended with size.
///
	func test_packAndUnpack_toData_bigEndian_String_utf32BigEndian_prependedWithSize() throws {
		let value = "I am a test string! 仮 🌙 Ok"
	
		let packer = self.packer(options: .stringsPrependedWithSize)
		try packer.pack(value, using: .utf32BigEndian)
	
		let data = try packer.data
	
		let unpacker = self.unpacker(source: data, options: .stringsPrependedWithSize)
		let result = try unpacker.unpack(type(of: value).self, using: .utf32BigEndian)

		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a String object into a stream, with utf32BigEndian encoding.
///
	func test_packAndUnpack_toStream_bigEndian_String_utf32BigEndian_prependedWithSize() throws {
		let value = "I am a test string! 仮 🌙 Ok"
		
		let data = try withOutputStream(size: 512) {
			let packer = self.packer(destination: $0, options: .stringsPrependedWithSize)
			try packer.pack(value, using: .utf32BigEndian)
		}

		var result: String = ""
		try withInputStream(wrapping: data) {
			let unpacker = self.unpacker(source: $0, options: .stringsPrependedWithSize)
			result = try unpacker.unpack(type(of: value).self, using: .utf32BigEndian)
		}
		
		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a String object into a data object, with utf32LittleEndian
/// encoding and the string prepended with size.
///
	func test_packAndUnpack_toData_bigEndian_String_utf32LittleEndian_prependedWithSize() throws {
		let value = "I am a test string! 仮 🌙 Ok"
	
		let packer = self.packer(options: .stringsPrependedWithSize)
		try packer.pack(value, using: .utf32LittleEndian)
	
		let data = try packer.data
	
		let unpacker = self.unpacker(source: data, options: .stringsPrependedWithSize)
		let result = try unpacker.unpack(type(of: value).self, using: .utf32LittleEndian)

		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing a String object into a stream, with utf32LittleEndian encoding.
///
	func test_packAndUnpack_toStream_bigEndian_String_utf32LittleEndian_prependedWithSize() throws {
		let value = "I am a test string! 仮 🌙 Ok"
		
		let data = try withOutputStream(size: 512) {
			let packer = self.packer(destination: $0, options: .stringsPrependedWithSize)
			try packer.pack(value, using: .utf32LittleEndian)
		}

		var result: String = ""
		try withInputStream(wrapping: data) {
			let unpacker = self.unpacker(source: $0, options: .stringsPrependedWithSize)
			result = try unpacker.unpack(type(of: value).self, using: .utf32LittleEndian)
		}
		
		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing mixed types into a data object.
///
	func test_packAndUnpack_toData_bigEndian_mixed() throws {
		let intValue = 1234
		let doubleValue = 678.987654321
		let stringValue = "I am a test string! 仮 🌙 Ok"
		let floatValue: Float = 0.7728
	
		let packer = self.packer()
		
		try packer.pack(intValue)
		try packer.pack(doubleValue)
		try packer.pack(stringValue, using: .utf8)
		try packer.pack(floatValue)
	
		let data = try packer.data
	
		let unpacker = self.unpacker(source: data)
		
		let intResult = try unpacker.unpack(type(of: intValue).self)
		let doubleResult = try unpacker.unpack(type(of: doubleValue).self)
		let stringResult = try unpacker.unpack(type(of: stringValue).self, using: .utf8)
		let floatResult = try unpacker.unpack(type(of: floatValue).self)

		XCTAssertTrue(intValue == intResult, "The unpacked data does not match the original value.")
		XCTAssertTrue(doubleValue == doubleResult, "The unpacked data does not match the original value.")
		XCTAssertTrue(stringValue == stringResult, "The unpacked data does not match the original value.")
		XCTAssertTrue(floatValue == floatResult, "The unpacked data does not match the original value.")
	}
	
/// Tests packing mixed types into a stream.
///
	func test_packAndUnpack_toStream_bigEndian_mixed() throws {
		let intValue = 1234
		let doubleValue = 678.987654321
		let stringValue = "I am a test string! 仮 🌙 Ok"
		let floatValue: Float = 0.7728
		
		let data = try withOutputStream(size: 1024) {
			let packer = self.packer(destination: $0)
			
			try packer.pack(intValue)
			try packer.pack(doubleValue)
			try packer.pack(stringValue, using: .utf8)
			try packer.pack(floatValue)
		}

		try withInputStream(wrapping: data) {
			let unpacker = self.unpacker(source: $0)
			
			let intResult = try unpacker.unpack(type(of: intValue).self)
			let doubleResult = try unpacker.unpack(type(of: doubleValue).self)
			let stringResult = try unpacker.unpack(type(of: stringValue).self, using: .utf8)
			let floatResult = try unpacker.unpack(type(of: floatValue).self)

			XCTAssertTrue(intValue == intResult, "The unpacked data does not match the original value.")
			XCTAssertTrue(doubleValue == doubleResult, "The unpacked data does not match the original value.")
			XCTAssertTrue(stringValue == stringResult, "The unpacked data does not match the original value.")
			XCTAssertTrue(floatValue == floatResult, "The unpacked data does not match the original value.")
		}
	}
}
