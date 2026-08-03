//
//  StringTests.swift
//  PackTests
//
//  Created by Matt Cox on 03/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Foundation
import Testing

@testable import Pack

private let allFramings: [StringFraming] = [
	.lengthPrefixed(.uint8),
	.lengthPrefixed(.uint16),
	.lengthPrefixed(.uint32),
	.lengthPrefixed(.uint64),
	.nullTerminated,
	.fixed(byteCount: 32),
]

@Suite("Strings")
struct StringTests {
	@Test("Strings round trip under every framing", arguments: allFramings)
	func roundTrip(framing: StringFraming) throws {
		let data = try packedToData(.littleEndian) { packer in
			try packer.pack("Hello, world!", using: .utf8, framing: framing)
			try packer.pack(UInt32(0xdeadbeef))
		}

		var unpacker = dataUnpacker(data, .littleEndian)

		#expect(try unpacker.unpack(String.self, using: .utf8, framing: framing) == "Hello, world!")
		#expect(try unpacker.unpack(UInt32.self) == 0xdeadbeef)
	}

// Pack 1 always wrote a null terminator but only consumed one when the
// decoded length was greater than zero, so an empty string desynchronised the
// stream. The framings are mutually exclusive now, but the empty case is
// still worth pinning for each of them.
//
	@Test("Empty strings round trip without desynchronising", arguments: allFramings)
	func emptyString(framing: StringFraming) throws {
		let data = try packedToData(.littleEndian) { packer in
			try packer.pack("", using: .utf8, framing: framing)
			try packer.pack(UInt32(0xdeadbeef))
		}

		var unpacker = dataUnpacker(data, .littleEndian)

		#expect(try unpacker.unpack(String.self, using: .utf8, framing: framing) == "")
		#expect(try unpacker.unpack(UInt32.self) == 0xdeadbeef)
	}

	@Test("A length prefix records the byte count, not the character count")
	func lengthPrefixGolden() throws {
		let data = try packedToData(.bigEndian) { packer in
			try packer.pack("é", using: .utf8, framing: .lengthPrefixed(.uint32))
		}

		// Two bytes of utf8, preceded by a four byte count.
		//
		#expect(data.hex == "00000002" + "c3a9")
	}

	@Test("Fixed size strings are padded, and the padding is stripped")
	func fixedSizePadding() throws {
		let data = try packedToData(.bigEndian) { packer in
			try packer.pack("FORM", using: .ascii, framing: .fixed(byteCount: 4))
			try packer.pack("ID", using: .ascii, framing: .fixed(byteCount: 4, padding: 0x20))
		}

		#expect(data.hex == "464f524d" + "49442020")

		var unpacker = dataUnpacker(data, .bigEndian)

		#expect(try unpacker.unpack(String.self, using: .ascii, framing: .fixed(byteCount: 4)) == "FORM")
		#expect(try unpacker.unpack(String.self, using: .ascii, framing: .fixed(byteCount: 4, padding: 0x20)) == "ID")
	}

	@Test("A string too long for a fixed size field is rejected, not truncated")
	func fixedSizeOverflow() {
		expectPackError(.valueOutOfRange) {
			_ = try packedToData(.bigEndian) { packer in
				try packer.pack("TOOLONG", using: .ascii, framing: .fixed(byteCount: 4))
			}
		}
	}

	@Test("A string too long for its length prefix is rejected")
	func lengthPrefixOverflow() {
		expectPackError(.valueOutOfRange) {
			_ = try packedToData(.bigEndian) { packer in
				try packer.pack(String(repeating: "a", count: 300), using: .ascii, framing: .lengthPrefixed(.uint8))
			}
		}
	}

	@Test("Null terminated framing rejects encodings that can contain zero bytes")
	func nullTerminatedEncoding() {
		expectPackError(.unsupportedEncoding) {
			_ = try packedToData(.bigEndian) { packer in
				try packer.pack("Hello", using: .utf16, framing: .nullTerminated)
			}
		}
	}

	@Test("A null terminated string containing a null character is rejected")
	func nullTerminatedEmbeddedNull() {
		expectPackError(.invalidString) {
			_ = try packedToData(.bigEndian) { packer in
				try packer.pack("a\u{0}b", using: .utf8, framing: .nullTerminated)
			}
		}
	}

	@Test("Strings framed to the end of the input round trip")
	func untilEnd() throws {
		let data = try packedToData(.littleEndian) { packer in
			try packer.pack(UInt32(7))
			try packer.pack("trailing", using: .utf8, framing: .untilEnd)
		}

		var unpacker = dataUnpacker(data, .littleEndian)

		#expect(try unpacker.unpack(UInt32.self) == 7)
		#expect(try unpacker.unpack(String.self, using: .utf8, framing: .untilEnd) == "trailing")

		// The same, from a stream, where the remaining length is unknowable.
		//
		var fromStream = streamUnpacker(data, .littleEndian)

		#expect(try fromStream.unpack(UInt32.self) == 7)
		#expect(try fromStream.unpack(String.self, using: .utf8, framing: .untilEnd) == "trailing")
	}

	@Test("The configuration supplies the default encoding and framing")
	func configurationDefaults() throws {
		let configuration = PackConfiguration(
			byteOrder: .bigEndian,
			defaultStringEncoding: .utf16BigEndian,
			defaultStringFraming: .lengthPrefixed(.uint16)
		)

		let data = try packedToData(configuration) { packer in
			try packer.pack("hi")
		}

		#expect(data.hex == "0004" + "00680069")

		var unpacker = dataUnpacker(data, configuration)

		#expect(try unpacker.unpack(String.self) == "hi")
	}

	@Test("Bytes that are invalid in the requested encoding are reported")
	func invalidEncoding() throws {
		let data = Data([0x00, 0x00, 0x00, 0x02, 0xff, 0xfe])
		var unpacker = dataUnpacker(data, .bigEndian)

		expectPackError(.invalidString) {
			_ = try unpacker.unpack(String.self, using: .utf8, framing: .lengthPrefixed(.uint32))
		}
	}
}
