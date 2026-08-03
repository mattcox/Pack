//
//  CollectionTests.swift
//  PackTests
//
//  Created by Matt Cox on 03/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Foundation
import Testing

@testable import Pack

@Suite("Collections")
struct CollectionTests {
// The bulk paths take a shortcut when no reordering is needed, so both byte
// orders have to be checked - one exercises the fast path on a little endian
// host, the other the per element path.
//
	@Test("Integer collections round trip", arguments: [PackConfiguration.littleEndian, .bigEndian])
	func integerCollection(configuration: PackConfiguration) throws {
		let values: [UInt32] = [0x00000000, 0x11223344, 0xaabbccdd, 0xffffffff]

		let data = try packedToData(configuration) { packer in
			try packer.pack(contentsOf: values)
		}

		#expect(data.count == values.count * 4)

		var unpacker = dataUnpacker(data, configuration)

		#expect(try unpacker.unpack(UInt32.self, count: values.count) == values)
	}

	@Test("Bulk and per element packing agree", arguments: [PackConfiguration.littleEndian, .bigEndian])
	func bulkMatchesIndividual(configuration: PackConfiguration) throws {
		let values: [Int16] = [-32768, -1, 0, 1, 32767]

		let bulk = try packedToData(configuration) { packer in
			try packer.pack(contentsOf: values)
		}

		let individual = try packedToData(configuration) { packer in
			for value in values {
				try packer.pack(value)
			}
		}

		#expect(bulk == individual)
	}

	@Test("Floating point collections round trip", arguments: [PackConfiguration.littleEndian, .bigEndian])
	func floatingPointCollection(configuration: PackConfiguration) throws {
		let floats: [Float] = [.pi, -0.5, 0, .greatestFiniteMagnitude]
		let doubles: [Double] = [.pi, -0.5, 0, .greatestFiniteMagnitude]

		let data = try packedToData(configuration) { packer in
			try packer.pack(contentsOf: floats)
			try packer.pack(contentsOf: doubles)
		}

		var unpacker = dataUnpacker(data, configuration)

		#expect(try unpacker.unpack(Float.self, count: floats.count) == floats)
		#expect(try unpacker.unpack(Double.self, count: doubles.count) == doubles)
	}

	@Test("Count prefixed collections round trip")
	func countPrefixed() throws {
		let values: [UInt16] = [1, 2, 3, 4, 5]

		let data = try packedToData(.bigEndian) { packer in
			try packer.pack(contentsOf: values, countPrefixedBy: .uint32)
		}

		#expect(data.hex == "00000005" + "0001000200030004" + "0005")

		var unpacker = dataUnpacker(data, .bigEndian)

		#expect(try unpacker.unpack(UInt16.self, countPrefixedBy: .uint32) == values)
	}

	@Test("An empty collection round trips")
	func emptyCollection() throws {
		let values: [UInt64] = []

		let data = try packedToData(.bigEndian) { packer in
			try packer.pack(contentsOf: values, countPrefixedBy: .uint16)
			try packer.pack(UInt8(0xff))
		}

		#expect(data.hex == "0000" + "ff")

		var unpacker = dataUnpacker(data, .bigEndian)
		let unpacked: [UInt64] = try unpacker.unpack(UInt64.self, countPrefixedBy: .uint16)

		#expect(unpacked == [])
		#expect(try unpacker.unpack(UInt8.self) == 0xff)
	}

	@Test("A count too large for its prefix width is reported")
	func countTooLarge() {
		expectPackError(.valueOutOfRange) {
			_ = try packedToData(.bigEndian) { packer in
				try packer.pack(contentsOf: [UInt8](repeating: 0, count: 300), countPrefixedBy: .uint8)
			}
		}
	}

	@Test("Raw bytes are packed unchanged, whatever the byte order")
	func rawData() throws {
		let bytes = Data([0x01, 0x02, 0x03, 0x04])

		for configuration in [PackConfiguration.littleEndian, .bigEndian] {
			let data = try packedToData(configuration) { packer in
				try packer.pack(bytes)
			}

			#expect(data == bytes)

			var unpacker = dataUnpacker(data, configuration)
			let unpacked = try unpacker.unpack(Data.self, byteCount: 4)

			#expect(unpacked == bytes)
		}
	}
}
