//
//  ErasureTests.swift
//  PackTests
//
//  Created by Matt Cox on 03/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Foundation
import Testing

@testable import Pack

private func writeChunk<P: Packer>(to packer: inout P) throws {
	try packer.pack("CHNK", using: .ascii, framing: .fixed(byteCount: 4))
	try packer.withLengthPrefix(.uint64) { packer in
		try packer.pack(Double.pi)
		try packer.pack(contentsOf: [UInt32(1), 2, 3], countPrefixedBy: .uint32)
	}
}

@Suite("Erasure")
struct ErasureTests {
// The point of AnyPacker is that erasing changes nothing about the output.
// If these diverge, a client forced to erase would be writing a different
// file to one that is statically typed.
//
	@Test("Erased and concrete packers produce identical bytes")
	func erasureEquivalence() throws {
		let concrete = try packedToData(.littleEndian, writeChunk)

		let backing = BinaryPacker(configuration: .littleEndian)
		var erased = AnyPacker(backing)
		try writeChunk(to: &erased)

		#expect(backing.data == concrete)
	}

	@Test("Erasure preserves framing through a stream, which buffers")
	func erasureThroughStream() throws {
		let stream = OutputStream.toMemory()
		stream.open()

		let backing = BinaryPacker(writingTo: stream, configuration: .bigEndian)
		var erased = AnyPacker(backing)

		try erased.withLengthPrefix(.uint32) { packer in
			try packer.pack(UInt16(7))
			try packer.withLengthPrefix(.uint16) { packer in
				try packer.pack(UInt8(8))
			}
		}

		let data = stream.property(forKey: .dataWrittenToMemoryStreamKey) as? Data ?? Data()
		stream.close()

		// The outer body is 0007, the inner span's two byte prefix, and 08 -
		// five bytes.
		//
		#expect(data.hex == "00000005" + "0007" + "0001" + "08")
	}

	@Test("An erased unpacker reads what an erased packer wrote")
	func erasedRoundTrip() throws {
		let backing = BinaryPacker(configuration: .littleEndian)
		var packer = AnyPacker(backing)

		let color = Color(name: "Erased", red: 0.1, green: 0.2, blue: 0.3)
		try packer.pack(color)

		var unpacker = AnyUnpacker(BinaryUnpacker(from: backing.data, configuration: .littleEndian))
		let unpacked = try unpacker.unpack(Color.self)

		#expect(unpacked == color)
	}

	@Test("A placeholder from an erased packer is still rejected elsewhere")
	func erasedPlaceholderIdentity() throws {
		var first = AnyPacker(BinaryPacker(configuration: .bigEndian))
		var second = AnyPacker(BinaryPacker(configuration: .bigEndian))

		let placeholder = try first.reserve(UInt32.self)

		expectPackError(.invalidPlaceholder) {
			try second.fill(placeholder, with: UInt32(1))
		}
	}

	@Test("Wrapping an erased packer does not add a second layer")
	func doubleErasure() throws {
		let backing = BinaryPacker(configuration: .bigEndian)
		let once = AnyPacker(backing)
		var twice = AnyPacker(once)

		try twice.pack(UInt16(0x1234))

		#expect(backing.data.hex == "1234")
	}

	@Test("Erasure forwards position and capability")
	func forwardsMetadata() throws {
		let backing = BinaryPacker(configuration: .bigEndian)
		var erased = AnyPacker(backing)

		#expect(erased.patchesInPlace == true)
		#expect(erased.configuration.byteOrder == .bigEndian)
		#expect(erased.packedCount == 0)

		try erased.pack(UInt32(1))

		#expect(erased.packedCount == 4)
		#expect(backing.packedCount == 4)
	}

	@Test("Erasure forwards user info")
	func forwardsUserInfo() throws {
		let key = PackUserInfoKey(rawValue: "test")
		let backing = BinaryPacker(configuration: .bigEndian)
		let erased = AnyPacker(backing)

		erased.userInfo[key] = 42

		#expect(backing.userInfo[key] as? Int == 42)
		#expect(erased.userInfo[key] as? Int == 42)
	}

// The shape a client is forced into when the packer type cannot be known at
// the point a closure is captured. This is what AnyPacker exists for.
//
	@Test("A closure captured before any packer existed can still pack")
	func closureCapturedAheadOfTime() throws {
		typealias Packing = (Any, inout AnyPacker) throws -> Void

		var registry: [String: Packing] = [:]
		registry["color"] = { value, packer in
			guard let color = value as? Color else {
				return
			}

			try packer.pack(color)
		}

		let color = Color(name: "Late", red: 1, green: 0, blue: 0)

		let backing = BinaryPacker(configuration: .littleEndian)
		var packer = AnyPacker(backing)
		try registry["color"]?(color, &packer)

		var unpacker = BinaryUnpacker(from: backing.data, configuration: .littleEndian)
		let unpacked = try unpacker.unpack(Color.self)

		#expect(unpacked == color)
	}
}
