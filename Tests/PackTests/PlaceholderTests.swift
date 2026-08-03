//
//  PlaceholderTests.swift
//  PackTests
//
//  Created by Matt Cox on 03/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Foundation
import Testing

@testable import Pack

@Suite("Placeholders")
struct PlaceholderTests {
	@Test("A reserved slot is filled in place")
	func reserveAndFill() throws {
		var packer = BinaryPacker(configuration: .bigEndian)

		let placeholder = try packer.reserve(UInt32.self)
		try packer.pack(UInt16(0xaaaa))
		try packer.fill(placeholder, with: UInt32(0xdeadbeef))

		#expect(packer.data.hex == "deadbeef" + "aaaa")
		#expect(packer.hasOpenPlaceholders == false)
	}

	@Test("An unfilled slot is reported")
	func openPlaceholder() throws {
		var packer = BinaryPacker(configuration: .bigEndian)

		_ = try packer.reserve(UInt32.self)
		try packer.pack(UInt16(0xaaaa))

		#expect(packer.hasOpenPlaceholders == true)
		#expect(packer.data.hex == "00000000" + "aaaa")
	}

	@Test("A placeholder from another packer is rejected")
	func wrongOwner() throws {
		var first = BinaryPacker(configuration: .bigEndian)
		var second = BinaryPacker(configuration: .bigEndian)

		let placeholder = try first.reserve(UInt32.self)

		expectPackError(.invalidPlaceholder) {
			try second.fill(placeholder, with: UInt32(1))
		}
	}

	@Test("A placeholder cannot be filled twice")
	func doubleFill() throws {
		var packer = BinaryPacker(configuration: .bigEndian)

		let placeholder = try packer.reserve(UInt32.self)
		try packer.fill(placeholder, with: UInt32(1))

		expectPackError(.placeholderAlreadyFilled) {
			try packer.fill(placeholder, with: UInt32(2))
		}
	}

	@Test("A value of the wrong width cannot fill a placeholder")
	func mismatchedWidth() throws {
		var packer = BinaryPacker(configuration: .bigEndian)

		let placeholder = try packer.reserve(UInt32.self)

		expectPackError(.valueOutOfRange) {
			try packer.fill(placeholder, with: UInt16(1))
		}
	}

// Filling out of order has to behave the same everywhere, because a caller
// cannot see which destination they will be handed. A buffering destination
// holds the span until everything ahead of it is resolved; a patchable one
// revises in place. Only peak memory differs.
//
	@Test("Fills are accepted in any order on every destination")
	func outOfOrderFill() throws {
		var inMemory = BinaryPacker(configuration: .bigEndian)
		let firstSlot = try inMemory.reserve(UInt32.self)
		try inMemory.pack(UInt8(0xaa))
		let secondSlot = try inMemory.reserve(UInt32.self)
		try inMemory.pack(UInt8(0xbb))

		// Outermost filled first, which a buffering destination cannot write
		// out until it arrives.
		//
		try inMemory.fill(firstSlot, with: UInt32(1))
		try inMemory.fill(secondSlot, with: UInt32(2))
		try inMemory.finish()

		let onStream = try packedToStream(.bigEndian) { packer in
			let firstSlot = try packer.reserve(UInt32.self)
			try packer.pack(UInt8(0xaa))
			let secondSlot = try packer.reserve(UInt32.self)
			try packer.pack(UInt8(0xbb))

			try packer.fill(firstSlot, with: UInt32(1))
			try packer.fill(secondSlot, with: UInt32(2))
			try packer.finish()
		}

		#expect(inMemory.data.hex == "00000001" + "aa" + "00000002" + "bb")
		#expect(inMemory.data == onStream)
	}

	@Test("Reversed fills also agree across destinations")
	func reversedFill() throws {
		var inMemory = BinaryPacker(configuration: .bigEndian)
		let firstSlot = try inMemory.reserve(UInt32.self)
		try inMemory.pack(UInt8(0xaa))
		let secondSlot = try inMemory.reserve(UInt32.self)
		try inMemory.pack(UInt8(0xbb))

		try inMemory.fill(secondSlot, with: UInt32(2))
		try inMemory.fill(firstSlot, with: UInt32(1))
		try inMemory.finish()

		let onStream = try packedToStream(.bigEndian) { packer in
			let firstSlot = try packer.reserve(UInt32.self)
			try packer.pack(UInt8(0xaa))
			let secondSlot = try packer.reserve(UInt32.self)
			try packer.pack(UInt8(0xbb))

			try packer.fill(secondSlot, with: UInt32(2))
			try packer.fill(firstSlot, with: UInt32(1))
			try packer.finish()
		}

		#expect(inMemory.data.hex == "00000001" + "aa" + "00000002" + "bb")
		#expect(inMemory.data == onStream)
	}

	@Test("A measuring packer accepts fills in any order too")
	func outOfOrderFillWhileMeasuring() throws {
		var measure = MeasuringPacker(configuration: .bigEndian)

		let firstSlot = try measure.reserve(UInt32.self)
		try measure.pack(UInt8(0xaa))
		let secondSlot = try measure.reserve(UInt32.self)
		try measure.pack(UInt8(0xbb))

		try measure.fill(firstSlot, with: UInt32(1))
		try measure.fill(secondSlot, with: UInt32(2))
		try measure.finish()

		#expect(measure.packedCount == 10)
	}

// A packer counts from zero, so its placeholder offsets are relative to
// itself. A destination holding bytes already has to account for that, or the
// patch lands over the preamble and the reserved slot is left as it was.
//
	@Test("Packing after existing bytes preserves them and patches the right slot")
	func seededDestination() throws {
		let preamble = Data([0xaa, 0xaa, 0xaa, 0xaa])
		var packer = BinaryPacker(
			destination: DataDestination(preamble),
			configuration: .littleEndian
		)

		try packer.withLengthPrefix(.uint32) { packer in
			try packer.pack(UInt32(0xbbbbbbbb))
		}

		try packer.finish()

		#expect(packer.data.hex == "aaaaaaaa" + "04000000" + "bbbbbbbb")
		#expect(packer.data.prefix(4) == preamble)
	}

	@Test("A seeded destination counts only what was packed into it")
	func seededDestinationCount() throws {
		var packer = BinaryPacker(
			destination: DataDestination(Data([0xaa, 0xaa, 0xaa, 0xaa])),
			configuration: .littleEndian
		)

		try packer.pack(UInt32(0))

		#expect(packer.packedCount == 4)
		#expect(packer.destination.count == 4)
		#expect(packer.data.count == 8)
	}

	@Test("A seeded destination cannot be patched over its preamble")
	func seededDestinationBounds() throws {
		var destination = DataDestination(Data([0xaa, 0xaa]))
		var bytes: [UInt8] = [0xff, 0xff]

		expectPackError(.destinationFailure) {
			try bytes.withUnsafeMutableBytes { buffer in
				try destination.patch(at: 0, with: UnsafeRawBufferPointer(buffer))
			}
		}

		#expect(destination.data.hex == "aaaa")
	}

// A span whose body throws is never filled. On a buffering destination its
// bytes are held and everything after it is swallowed, so the output looks
// finished but is not. finish() is what makes that visible.
//
	@Test("An abandoned span is reported rather than silently dropped")
	func abandonedSpanIsReported() throws {
		struct Marker: Error {

		}

		let stream = OutputStream.toMemory()
		stream.open()

		defer {
			stream.close()
		}

		var packer = BinaryPacker(writingTo: stream, configuration: .bigEndian)
		try packer.pack(UInt32(0xdeadbeef))

		#expect(throws: Marker.self) {
			try packer.withLengthPrefix(.uint32) { packer in
				try packer.pack(UInt16(1))
				throw Marker()
			}
		}

		#expect(packer.hasOpenPlaceholders == true)

		expectPackError(.incompleteOutput) {
			try packer.finish()
		}
	}

	@Test("An abandoned span is reported on a patchable destination too")
	func abandonedSpanInMemory() throws {
		struct Marker: Error {

		}

		var packer = BinaryPacker(configuration: .bigEndian)

		#expect(throws: Marker.self) {
			try packer.withLengthPrefix(.uint32) { packer in
				try packer.pack(UInt16(1))
				throw Marker()
			}
		}

		#expect(packer.hasOpenPlaceholders == true)

		expectPackError(.incompleteOutput) {
			try packer.finish()
		}
	}

	@Test("An incomplete state is visible through erasure")
	func abandonedSpanThroughErasure() throws {
		var erased = AnyPacker(BinaryPacker(configuration: .bigEndian))

		_ = try erased.reserve(UInt32.self)

		#expect(erased.hasOpenPlaceholders == true)

		expectPackError(.incompleteOutput) {
			try erased.finish()
		}
	}

	@Test("finish succeeds once every slot is filled")
	func finishSucceeds() throws {
		var packer = BinaryPacker(configuration: .bigEndian)

		try packer.withLengthPrefix(.uint32) { packer in
			try packer.pack(UInt16(1))
		}

		#expect(packer.hasOpenPlaceholders == false)
		try packer.finish()
	}

	@Test("A packer reports whether it patches in place")
	func patchesInPlace() throws {
		var packer = BinaryPacker(configuration: .bigEndian)
		#expect(packer.patchesInPlace == true)
		try packer.pack(UInt8(0))

		_ = try packedToStream(.bigEndian) { packer in
			#expect(packer.patchesInPlace == false)
			try packer.pack(UInt8(0))
		}
	}
}
