//
//  BinaryPackTests_packed.swift
//  PackTests
//
//  Created by Matt Cox on 13/02/2022.
//  Copyright © 2024 Matt Cox. All rights reserved.
//

import XCTest
@testable import Pack
import Foundation

final class BinaryPackTests_packed: XCTestCase {
	private func packer(options: BinaryPack.Options = BinaryPack.defaultOptions) -> BinaryPack {
		BinaryPack(options: options)
	}
	
	private func packer(destination: OutputStream, options: BinaryPack.Options = BinaryPack.defaultOptions) -> BinaryPack {
		BinaryPack(writingTo: destination, options: options)
	}
	
	private func unpacker(source: Data, options: BinaryPack.Options = BinaryPack.defaultOptions) -> BinaryPack {
		BinaryPack(from: source, options: options)
	}
	
	private func unpacker(source: InputStream, options: BinaryPack.Options = BinaryPack.defaultOptions) -> BinaryPack {
		BinaryPack(readingFrom: source, options: options)
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
	
/// A user info key that is used for testing the user info functionality.
///
	static let userInfoKey = PackUserInfoKey(rawValue: "TestKey")

/// Custom types that conforms to packable.
///
	private struct MyNestedType: Equatable, Packed {
		let intValue: Int
		let stringValue: String
		let doubleValue: Double
		
		init() {
			self.intValue = 9876
			self.stringValue = "🌙🧀"
			self.doubleValue = 54321.12345
		}
		
		init(from unpacker: inout Unpacker) throws {
			XCTAssertEqual(unpacker.userInfo[userInfoKey] as? String, "First")
			unpacker.userInfo[userInfoKey] = "Second"
		
			self.intValue = try unpacker.unpack(Int.self)
			self.stringValue = try unpacker.unpack(String.self, using: .utf8)
			self.doubleValue = try unpacker.unpack(Double.self)
		}
		
		func pack(to packer: inout Packer) throws {
			XCTAssertEqual(packer.userInfo[userInfoKey] as? String, "First")
			packer.userInfo[userInfoKey] = "Second"
			
			try packer.pack(self.intValue)
			try packer.pack(self.stringValue, using: .utf8)
			try packer.pack(self.doubleValue)
		}
	}
	
	private struct MyType: Equatable, Packed {
		let intValue: Int
		let nestedValue: MyNestedType
		let doubleValue: Double
		let stringValue: String
		let floatValue: Float
		
		init() {
			self.intValue = 1234
			self.nestedValue = MyNestedType()
			self.doubleValue = 678.987654321
			self.stringValue = "I am a test string! 仮 🌙 Ok"
			self.floatValue = 0.7728
		}
		
		init(from unpacker: inout Unpacker) throws {
			self.intValue = try unpacker.unpack(Int.self)
			
			unpacker.userInfo[userInfoKey] = "First"
			self.nestedValue = try unpacker.unpack(MyNestedType.self)
			XCTAssertEqual(unpacker.userInfo[userInfoKey] as? String, "Second")
			
			self.doubleValue = try unpacker.unpack(Double.self)
			self.stringValue = try unpacker.unpack(String.self, using: .utf8)
			self.floatValue = try unpacker.unpack(Float.self)
		}
		
		func pack(to packer: inout Packer) throws {
			try packer.pack(self.intValue)
			
			packer.userInfo[userInfoKey] = "First"
			try packer.pack(self.nestedValue)
			XCTAssertEqual(packer.userInfo[userInfoKey] as? String, "Second")
			
			try packer.pack(self.doubleValue)
			try packer.pack(self.stringValue, using: .utf8)
			try packer.pack(self.floatValue)
		}
	}

/// Tests packing an object that conforms to packable into a data object.
///
	func test_packAndUnpack_toData_packed() throws {
		let value = MyType()

		let packer = self.packer()
		try packer.pack(value)
	
		let data = try packer.data
	
		let unpacker = self.unpacker(source: data)
		let result = try unpacker.unpack(MyType.self)

		XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
	}
	
/// Tests packing an object that conforms to packable into a stream.
///
	func test_packAndUnpack_toStream_packed() throws {
		let value = MyType()
		
		let data = try withOutputStream(size: 1024) {
			let packer = self.packer(destination: $0)
			try packer.pack(value)
		}

		try withInputStream(wrapping: data) {
			let unpacker = self.unpacker(source: $0)
			let result = try unpacker.unpack(type(of: value).self)

			XCTAssertTrue(value == result, "The unpacked data does not match the original value.")
		}
	}
}
