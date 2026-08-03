//
//  FramingTests.swift
//  PackTests
//
//  Created by Matt Cox on 03/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Foundation
import Testing

@testable import Pack

// Written as generic functions rather than closures, so the same body can be
// handed to packers with different destinations and specialise for each.
//
private func writeChunk<P: Packer>(to packer: inout P) throws {
	try packer.pack("MESH", using: .ascii, framing: .fixed(byteCount: 4))
	try packer.withLengthPrefix(.uint64) { packer in
		try packer.pack(Double.pi)
		try packer.pack(contentsOf: [Float(1), Float(2), Float(3)], countPrefixedBy: .uint32)
		try packer.pack("named", framing: .lengthPrefixed(.uint16))
	}
	try packer.pack(UInt32(0xdeadbeef))
}

private func writeNestedChunks<P: Packer>(to packer: inout P) throws {
	try packer.withLengthPrefix(.uint32) { packer in
		try packer.pack(UInt8(1))

		try packer.withLengthPrefix(.uint32) { packer in
			try packer.pack(UInt8(2))

			try packer.withLengthPrefix(.uint16) { packer in
				try packer.pack(UInt8(3))
			}
		}

		try packer.pack(UInt8(4))
	}
}

private func writeEmptySpan<P: Packer>(to packer: inout P) throws {
	try packer.withLengthPrefix(.uint32) { _ in

	}

	try packer.pack(UInt8(0xff))
}

@Suite("Framing")
struct FramingTests {
// The invariant the buffering design exists to guarantee: a packer that can
// patch its output and a packer that cannot must produce the same bytes for
// the same calls. If this fails, the framing is not portable between a file
// written to memory and one written to a stream.
//
	@Test("Memory and stream destinations produce identical bytes")
	func byteIdentity() throws {
		let fromData = try packedToData(.littleEndian, writeChunk)
		let fromStream = try packedToStream(.littleEndian, writeChunk)

		#expect(fromData == fromStream)
		#expect(!fromData.isEmpty)
	}

	@Test("Nested spans produce identical bytes on both destinations")
	func byteIdentityNested() throws {
		let fromData = try packedToData(.bigEndian, writeNestedChunks)
		let fromStream = try packedToStream(.bigEndian, writeNestedChunks)

		#expect(fromData == fromStream)

		// A span's length covers its body only, not its own prefix. The outer
		// body is 01, the inner span's four byte prefix, the inner body, and
		// 04 - ten bytes. The inner body is 02, the innermost two byte prefix
		// and 03 - four bytes. The innermost body is 03 alone.
		//
		#expect(fromData.hex == "0000000a" + "01" + "00000004" + "02" + "0001" + "03" + "04")
	}

	@Test("An empty span records a length of zero")
	func emptySpan() throws {
		let fromData = try packedToData(.bigEndian, writeEmptySpan)
		let fromStream = try packedToStream(.bigEndian, writeEmptySpan)

		#expect(fromData.hex == "00000000" + "ff")
		#expect(fromData == fromStream)
	}

	@Test("A length prefix too narrow for its span is reported")
	func spanTooLarge() {
		expectPackError(.valueOutOfRange) {
			_ = try packedToData(.bigEndian) { packer in
				try packer.withLengthPrefix(.uint8) { packer in
					try packer.pack(contentsOf: [UInt8](repeating: 0, count: 300))
				}
			}
		}
	}

	@Test("packedCount advances past reserved slots and buffered bodies")
	func packedCount() throws {
		_ = try packedToStream(.bigEndian) { packer in
			#expect(packer.packedCount == 0)

			try packer.withLengthPrefix(.uint32) { packer in
				#expect(packer.packedCount == 4)
				try packer.pack(UInt64(0))
				#expect(packer.packedCount == 12)
			}

			#expect(packer.packedCount == 12)
		}
	}

	@Test("A reader skips the remainder of a span it does not fully understand")
	func forwardCompatibility() throws {
		// A newer writer emits three fields within the span.
		//
		let data = try packedToData(.bigEndian) { packer in
			try packer.withLengthPrefix(.uint64) { packer in
				try packer.pack(UInt32(1))
				try packer.pack(UInt32(2))
				try packer.pack(UInt32(3))
			}

			try packer.pack(UInt32(0xdeadbeef))
		}

		// An older reader knows about only the first.
		//
		var unpacker = dataUnpacker(data, .bigEndian)
		let length = try unpacker.unpack(UInt64.self)

		let first = try unpacker.withLimit(byteCount: Int(length)) { unpacker in
			try unpacker.unpack(UInt32.self)
		}

		#expect(first == 1)

		// The remainder of the span was skipped, so what follows is still
		// readable.
		//
		#expect(try unpacker.unpack(UInt32.self) == 0xdeadbeef)
	}

	@Test("Reading past the end of a span is reported as it happens")
	func spanOverrun() throws {
		let data = try packedToData(.bigEndian) { packer in
			try packer.withLengthPrefix(.uint32) { packer in
				try packer.pack(UInt32(1))
			}

			try packer.pack(UInt32(0xdeadbeef))
		}

		var unpacker = dataUnpacker(data, .bigEndian)
		let length = try unpacker.unpack(UInt32.self)

		expectPackError(.overrun) {
			try unpacker.withLimit(byteCount: Int(length)) { unpacker in
				_ = try unpacker.unpack(UInt32.self)

				// The span holds four bytes. Reading a second value would run
				// into the value that follows the span.
				//
				_ = try unpacker.unpack(UInt32.self)
			}
		}
	}

	@Test("A span longer than the remaining input is rejected when it opens")
	func spanBeyondEndOfInput() throws {
		let data = try packedToData(.bigEndian) { packer in
			try packer.pack(UInt32(4))
		}

		var unpacker = dataUnpacker(data, .bigEndian)
		_ = try unpacker.unpack(UInt32.self)

		expectPackError(.endOfInput) {
			try unpacker.withLimit(byteCount: 1024) { _ in

			}
		}
	}

	@Test("A span cannot extend beyond the span enclosing it")
	func nestedSpanBeyondParent() throws {
		var unpacker = dataUnpacker(Data(repeating: 0, count: 64), .bigEndian)

		expectPackError(.overrun) {
			try unpacker.withLimit(byteCount: 8) { unpacker in
				try unpacker.withLimit(byteCount: 16) { _ in

				}
			}
		}
	}

	@Test("Nested spans round trip through a stream source")
	func nestedSpansFromStream() throws {
		let data = try packedToData(.bigEndian) { packer in
			try packer.withLengthPrefix(.uint32) { packer in
				try packer.pack(UInt16(7))

				try packer.withLengthPrefix(.uint32) { packer in
					try packer.pack(UInt16(8))
					try packer.pack(UInt16(9))
				}
			}
		}

		var unpacker = streamUnpacker(data, .bigEndian)
		let outer = try unpacker.unpack(UInt32.self)

		try unpacker.withLimit(byteCount: Int(outer)) { unpacker in
			let marker = try unpacker.unpack(UInt16.self)
			#expect(marker == 7)

			let inner = try unpacker.unpack(UInt32.self)

			// Only the first of the inner values is read; the limit skips the
			// rest, which on a stream means reading and discarding.
			//
			try unpacker.withLimit(byteCount: Int(inner)) { unpacker in
				let first = try unpacker.unpack(UInt16.self)
				#expect(first == 8)
			}
		}

		#expect(unpacker.unpackedCount == data.count)
	}

	@Test("unpackedCount and remainingCount track position")
	func position() throws {
		let data = try packedToData(.bigEndian) { packer in
			try packer.pack(UInt32(1))
			try packer.pack(UInt32(2))
			try packer.pack(UInt32(3))
		}

		var unpacker = dataUnpacker(data, .bigEndian)

		#expect(unpacker.unpackedCount == 0)
		#expect(unpacker.remainingCount == 12)

		_ = try unpacker.unpack(UInt32.self)

		#expect(unpacker.unpackedCount == 4)
		#expect(unpacker.remainingCount == 8)

		// Within a span, the remainder reported is the span's, not the
		// source's.
		//
		try unpacker.withLimit(byteCount: 4) { unpacker in
			#expect(unpacker.remainingCount == 4)
			_ = try unpacker.unpack(UInt16.self)
			#expect(unpacker.remainingCount == 2)
		}

		#expect(unpacker.unpackedCount == 8)
		#expect(unpacker.remainingCount == 4)
	}

	@Test("A stream source reports no remaining count outside a span")
	func streamRemainingCount() throws {
		let data = try packedToData(.bigEndian) { packer in
			try packer.pack(UInt32(1))
			try packer.pack(UInt32(2))
		}

		var unpacker = streamUnpacker(data, .bigEndian)

		#expect(unpacker.remainingCount == nil)

		try unpacker.withLimit(byteCount: 4) { unpacker in
			#expect(unpacker.remainingCount == 4)
		}

		#expect(unpacker.remainingCount == nil)
	}

	@Test("A failure inside a span leaves the position where it failed")
	func failureInsideSpanDoesNotSkip() throws {
		struct Marker: Error {

		}

		let data = try packedToData(.bigEndian) { packer in
			try packer.pack(UInt32(1))
			try packer.pack(UInt32(2))
		}

		var unpacker = dataUnpacker(data, .bigEndian)

		#expect(throws: Marker.self) {
			try unpacker.withLimit(byteCount: 8) { unpacker in
				_ = try unpacker.unpack(UInt32.self)
				throw Marker()
			}
		}

		// The span was not skipped past, so the second value is still there to
		// be read.
		//
		#expect(unpacker.unpackedCount == 4)
		#expect(try unpacker.unpack(UInt32.self) == 2)
	}
}
