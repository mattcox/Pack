//
//  ScalarTests.swift
//  PackTests
//
//  Created by Matt Cox on 03/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Foundation
import Testing

@testable import Pack

@Suite("Scalars")
struct ScalarTests {
// Golden expectations. These pin the encoding to specific bytes, so that a
// change to how values are encoded fails here rather than round tripping
// incorrectly against itself.
//
	@Test("Integers pack to known bytes, little endian")
	func integerGoldenLittleEndian() throws {
		let data = try packedToData(.littleEndian) { packer in
			try packer.pack(UInt8(0x12))
			try packer.pack(UInt16(0x1234))
			try packer.pack(UInt32(0x12345678))
			try packer.pack(UInt64(0x123456789abcdef0))
			try packer.pack(Int16(-2))
			try packer.pack(Int32(-2))
		}

		#expect(data.hex == "12" + "3412" + "78563412" + "f0debc9a78563412" + "feff" + "feffffff")
	}

	@Test("Integers pack to known bytes, big endian")
	func integerGoldenBigEndian() throws {
		let data = try packedToData(.bigEndian) { packer in
			try packer.pack(UInt8(0x12))
			try packer.pack(UInt16(0x1234))
			try packer.pack(UInt32(0x12345678))
			try packer.pack(UInt64(0x123456789abcdef0))
			try packer.pack(Int16(-2))
			try packer.pack(Int32(-2))
		}

		#expect(data.hex == "12" + "1234" + "12345678" + "123456789abcdef0" + "fffe" + "fffffffe")
	}

	@Test("Floating point values pack to their bit patterns")
	func floatingPointGolden() throws {
		let data = try packedToData(.bigEndian) { packer in
			try packer.pack(Float(1.0))
			try packer.pack(Double(1.0))
		}

		#expect(data.hex == "3f800000" + "3ff0000000000000")
	}

	@Test("Bool packs as a single byte")
	func boolGolden() throws {
		let data = try packedToData(.littleEndian) { packer in
			try packer.pack(true)
			try packer.pack(false)
		}

		#expect(data.hex == "0100")
	}

	@Test("Scalars round trip", arguments: [PackConfiguration.littleEndian, .bigEndian])
	func scalarRoundTrip(configuration: PackConfiguration) throws {
		let data = try packedToData(configuration) { packer in
			try packer.pack(Int8.min)
			try packer.pack(Int16.min)
			try packer.pack(Int32.min)
			try packer.pack(Int64.min)
			try packer.pack(UInt8.max)
			try packer.pack(UInt16.max)
			try packer.pack(UInt32.max)
			try packer.pack(UInt64.max)
			try packer.pack(Float.pi)
			try packer.pack(Double.pi)
			try packer.pack(true)
			try packer.pack(false)
		}

		var unpacker = dataUnpacker(data, configuration)

		#expect(try unpacker.unpack(Int8.self) == Int8.min)
		#expect(try unpacker.unpack(Int16.self) == Int16.min)
		#expect(try unpacker.unpack(Int32.self) == Int32.min)
		#expect(try unpacker.unpack(Int64.self) == Int64.min)
		#expect(try unpacker.unpack(UInt8.self) == UInt8.max)
		#expect(try unpacker.unpack(UInt16.self) == UInt16.max)
		#expect(try unpacker.unpack(UInt32.self) == UInt32.max)
		#expect(try unpacker.unpack(UInt64.self) == UInt64.max)
		#expect(try unpacker.unpack(Float.self) == Float.pi)
		#expect(try unpacker.unpack(Double.self) == Double.pi)
		#expect(try unpacker.unpack(Bool.self) == true)
		#expect(try unpacker.unpack(Bool.self) == false)
		#expect(unpacker.remainingCount == 0)
	}

// Erasing the value being packed - as opposed to erasing the packer - still
// works, because the argument is a normal parameter and Swift opens the
// existential into the generic one. This is the distinction that made
// AnyPacker necessary while `any Packable` remained usable.
//
	@Test("An existential Packable can be packed directly")
	func existentialPackable() throws {
		let values: [any Packable] = [Int32(-12345), UInt16(65535), true]

		let data = try packedToData(.bigEndian) { packer in
			for value in values {
				try packer.pack(value)
			}
		}

		var unpacker = dataUnpacker(data, .bigEndian)

		#expect(try unpacker.unpack(Int32.self) == -12345)
		#expect(try unpacker.unpack(UInt16.self) == 65535)
		#expect(try unpacker.unpack(Bool.self) == true)
	}

	@Test("Unpacking past the end of the source is reported")
	func endOfInput() throws {
		let data = try packedToData(.littleEndian) { packer in
			try packer.pack(UInt16(1))
		}

		var unpacker = dataUnpacker(data, .littleEndian)

		expectPackError(.endOfInput) {
			_ = try unpacker.unpack(UInt32.self)
		}
	}

	@Test("A Packable value round trips")
	func packableRoundTrip() throws {
		let color = Color(name: "Rebecca Purple", red: 0.4, green: 0.2, blue: 0.6)

		let data = try packedToData(.littleEndian) { packer in
			try packer.pack(color)
		}

		var unpacker = dataUnpacker(data, .littleEndian)

		#expect(try unpacker.unpack(Color.self) == color)
	}
}
