//
//  TestSupport.swift
//  PackTests
//
//  Created by Matt Cox on 03/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Foundation
import Testing

@testable import Pack

/// Packs into memory and returns the resulting bytes.
///
func packedToData(
	_ configuration: PackConfiguration,
	_ body: (inout BinaryPacker<DataDestination>) throws -> Void
) throws -> Data {
	var packer = BinaryPacker(configuration: configuration)
	try body(&packer)
	return packer.data
}

/// Packs into an in-memory `OutputStream` and returns the resulting bytes.
///
/// This exists so that the stream path - which cannot patch, and therefore
/// buffers reserved spans - can be compared against the memory path.
///
func packedToStream(
	_ configuration: PackConfiguration,
	_ body: (inout BinaryPacker<OutputStreamDestination>) throws -> Void
) throws -> Data {
	let stream = OutputStream.toMemory()
	stream.open()

	defer {
		stream.close()
	}

	var packer = BinaryPacker(writingTo: stream, configuration: configuration)
	try body(&packer)

	return stream.property(forKey: .dataWrittenToMemoryStreamKey) as? Data ?? Data()
}

/// An unpacker reading bytes held in memory.
///
/// This returns the unpacker rather than taking a closure, because `#expect`
/// cannot evaluate a throwing expression inside one.
///
func dataUnpacker(_ data: Data, _ configuration: PackConfiguration) -> BinaryUnpacker<DataSource> {
	BinaryUnpacker(from: data, configuration: configuration)
}

/// An unpacker reading from an in-memory `InputStream`.
///
/// The stream is retained by the source, and is left open for the lifetime of
/// the unpacker.
///
func streamUnpacker(_ data: Data, _ configuration: PackConfiguration) -> BinaryUnpacker<InputStreamSource> {
	let stream = InputStream(data: data)
	stream.open()

	return BinaryUnpacker(readingFrom: stream, configuration: configuration)
}

/// Asserts that a closure throws a ``PackError`` with the given code.
///
func expectPackError(
	_ code: PackError.Code,
	sourceLocation: SourceLocation = #_sourceLocation,
	_ body: () throws -> Void
) {
	do {
		try body()
		Issue.record("Expected PackError.\(code), but nothing was thrown", sourceLocation: sourceLocation)
	}
	catch let error as PackError {
		#expect(error.code == code, "Expected PackError.\(code), got \(error)", sourceLocation: sourceLocation)
	}
	catch {
		Issue.record("Expected PackError.\(code), got \(error)", sourceLocation: sourceLocation)
	}
}

extension Data {
/// The bytes as a lowercase hex string, for readable expectations.
///
	var hex: String {
		map {
			String(format: "%02x", $0)
		}
		.joined()
	}
}

/// A value with an explicit, hand written layout, used to exercise the
/// ``Packable`` and ``Unpackable`` conformances.
///
struct Color: Packed, Equatable {
	var name: String
	var red: Double
	var green: Double
	var blue: Double
	var alpha: Double

	init(name: String, red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
		self.name = name
		self.red = red
		self.green = green
		self.blue = blue
		self.alpha = alpha
	}

	init(from unpacker: inout some Unpacker) throws {
		self.name = try unpacker.unpack(String.self, using: .utf16, framing: .lengthPrefixed(.uint32))
		self.red = try unpacker.unpack(Double.self)
		self.green = try unpacker.unpack(Double.self)
		self.blue = try unpacker.unpack(Double.self)
		self.alpha = try unpacker.unpack(Double.self)
	}

	func pack(to packer: inout some Packer) throws {
		try packer.pack(name, using: .utf16, framing: .lengthPrefixed(.uint32))
		try packer.pack(red)
		try packer.pack(green)
		try packer.pack(blue)
		try packer.pack(alpha)
	}
}
