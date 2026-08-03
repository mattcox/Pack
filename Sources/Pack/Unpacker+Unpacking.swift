//
//  Unpacker+Unpacking.swift
//  Pack
//
//  Created by Matt Cox on 03/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Foundation

// The unpacking API, mirroring `Packer+Packing`. As there, none of this is a
// protocol requirement.
//
extension Unpacker {
/// Unpack a fixed width integer from the source.
///
/// - Parameters:
///   - type: The type of integer to unpack.
///
/// - Returns: The unpacked value.
///
/// - Throws: ``PackError`` if the source is exhausted, or the read would
/// pass the end of the innermost limited span.
///
	public mutating func unpack<T: PortableInteger>(_ type: T.Type) throws -> T {
		try unpackInteger(type)
	}

// The implementation behind every integer entry point. The public overloads
// forward here rather than to each other, so that the concrete overloads below
// cannot recurse into themselves.
//
	private mutating func unpackInteger<T: FixedWidthInteger>(_ type: T.Type) throws -> T {
		var value = T.zero
		try withUnsafeMutableBytes(of: &value) {
			try read(into: $0)
		}

		return configuration.byteOrder == .littleEndian ? T(littleEndian: value) : T(bigEndian: value)
	}

// Concrete overloads settling the ambiguity between the FixedWidthInteger and
// Unpackable entry points, as described in `Packer+Packing`.
//
	public mutating func unpack(_ type: Int8.Type) throws -> Int8 {
		try unpackInteger(type)
	}

	public mutating func unpack(_ type: Int16.Type) throws -> Int16 {
		try unpackInteger(type)
	}

	public mutating func unpack(_ type: Int32.Type) throws -> Int32 {
		try unpackInteger(type)
	}

	public mutating func unpack(_ type: Int64.Type) throws -> Int64 {
		try unpackInteger(type)
	}

	public mutating func unpack(_ type: UInt8.Type) throws -> UInt8 {
		try unpackInteger(type)
	}

	public mutating func unpack(_ type: UInt16.Type) throws -> UInt16 {
		try unpackInteger(type)
	}

	public mutating func unpack(_ type: UInt32.Type) throws -> UInt32 {
		try unpackInteger(type)
	}

	public mutating func unpack(_ type: UInt64.Type) throws -> UInt64 {
		try unpackInteger(type)
	}

/// Unpack a `Bool` from the source.
///
/// - Parameters:
///   - type: The type of object to unpack.
///
/// - Returns: The unpacked value.
///
/// - Throws: ``PackError`` if the source is exhausted, or the read would
/// pass the end of the innermost limited span.
///
	public mutating func unpack(_ type: Bool.Type) throws -> Bool {
		try unpack(UInt8.self) != 0
	}

/// Unpack a `Float` from the source.
///
/// - Parameters:
///   - type: The type of object to unpack.
///
/// - Returns: The unpacked value.
///
/// - Throws: ``PackError`` if the source is exhausted, or the read would
/// pass the end of the innermost limited span.
///
	public mutating func unpack(_ type: Float.Type) throws -> Float {
		Float(bitPattern: try unpack(UInt32.self))
	}

/// Unpack a `Double` from the source.
///
/// - Parameters:
///   - type: The type of object to unpack.
///
/// - Returns: The unpacked value.
///
/// - Throws: ``PackError`` if the source is exhausted, or the read would
/// pass the end of the innermost limited span.
///
	public mutating func unpack(_ type: Double.Type) throws -> Double {
		Double(bitPattern: try unpack(UInt64.self))
	}

/// Unpack raw bytes from the source, without interpreting them.
///
/// - Parameters:
///   - type: The type of object to unpack.
///   - byteCount: The number of bytes to read.
///
/// - Returns: The unpacked bytes.
///
/// - Throws: ``PackError`` if the source is exhausted, or the read would
/// pass the end of the innermost limited span.
///
	public mutating func unpack(_ type: Data.Type, byteCount: Int) throws -> Data {
		guard byteCount >= 0 else {
			throw PackError(
				.valueOutOfRange,
				offset: unpackedCount,
				reason: "Cannot read a negative number of bytes"
			)
		}

		guard byteCount > 0 else {
			return Data()
		}

		var data = Data(count: byteCount)
		try data.withUnsafeMutableBytes {
			try read(into: $0)
		}

		return data
	}

/// Unpack a type conforming to ``Unpackable`` from the source.
///
/// - Parameters:
///   - type: The type of object to unpack.
///
/// - Returns: The unpacked value.
///
/// - Throws: ``PackError`` if the value could not be unpacked.
///
	public mutating func unpack<T: Unpackable>(_ type: T.Type) throws -> T {
		try T(from: &self)
	}

/// Unpack a `String` from the source.
///
/// - Parameters:
///   - type: The type of object to unpack.
///   - encoding: The encoding the string was packed with. Defaults to the
///   encoding named by the unpacker's configuration.
///   - framing: How the extent of the string was recorded. Defaults to the
///   framing named by the unpacker's configuration.
///
/// - Returns: The unpacked value.
///
/// - Throws: ``PackError`` if the bytes are not valid in the given encoding,
/// if the encoding and framing are incompatible, or if the source is
/// exhausted.
///
	public mutating func unpack(
		_ type: String.Type,
		using encoding: String.Encoding? = nil,
		framing: StringFraming? = nil
	) throws -> String {
		let encoding = encoding ?? configuration.defaultStringEncoding
		let framing = framing ?? configuration.defaultStringFraming
		let offset = unpackedCount

		var data: Data
		switch framing {
			case .lengthPrefixed(let width):
				let byteCount = try unpack(count: width)
				data = try unpack(Data.self, byteCount: byteCount)

			case .nullTerminated:
				guard encoding == .ascii || encoding == .utf8 else {
					throw PackError(
						.unsupportedEncoding,
						offset: offset,
						reason: "Only ascii and utf8 strings may be null terminated"
					)
				}

				data = Data()
				while true {
					let byte = try unpack(UInt8.self)
					if byte == .zero {
						break
					}

					data.append(byte)
				}

			case .fixed(let byteCount, let padding):
				data = try unpack(Data.self, byteCount: byteCount)
				while data.last == padding {
					data.removeLast()
				}

			case .untilEnd:
				if let remainingCount {
					data = try unpack(Data.self, byteCount: remainingCount)
				}
				else {
					data = Data()
					while true {
						do {
							data.append(try unpack(UInt8.self))
						}
						catch let error as PackError where error.code == .endOfInput {
							break
						}
					}
				}
		}

		guard let string = String(data: data, encoding: encoding) else {
			throw PackError(
				.invalidString,
				offset: offset,
				reason: "The bytes are not valid in the requested encoding"
			)
		}

		return string
	}

/// Unpack a number of fixed width integers from the source.
///
/// - Parameters:
///   - type: The type of integer to unpack.
///   - count: The number of elements to unpack.
///
/// - Returns: The unpacked values, in order.
///
/// - Throws: ``PackError`` if the source is exhausted, or the read would
/// pass the end of the innermost limited span.
///
	public mutating func unpack<T: PortableInteger>(_ type: T.Type, count: Int) throws -> [T] {
		guard count >= 0 else {
			throw PackError(
				.valueOutOfRange,
				offset: unpackedCount,
				reason: "Cannot read a negative number of elements"
			)
		}

		guard count > 0 else {
			return []
		}

		var values = [T](repeating: .zero, count: count)
		try values.withUnsafeMutableBytes {
			try read(into: $0)
		}

		if MemoryLayout<T>.size > 1 && configuration.byteOrder != ByteOrder.system {
			for index in values.indices {
				values[index] = configuration.byteOrder == .littleEndian
					? T(littleEndian: values[index])
					: T(bigEndian: values[index])
			}
		}

		return values
	}

/// Unpack a number of `Float` values from the source.
///
/// - Parameters:
///   - type: The type of object to unpack.
///   - count: The number of elements to unpack.
///
/// - Returns: The unpacked values, in order.
///
/// - Throws: ``PackError`` if the source is exhausted, or the read would
/// pass the end of the innermost limited span.
///
	public mutating func unpack(_ type: Float.Type, count: Int) throws -> [Float] {
		try unpack(UInt32.self, count: count).map {
			Float(bitPattern: $0)
		}
	}

/// Unpack a number of `Double` values from the source.
///
/// - Parameters:
///   - type: The type of object to unpack.
///   - count: The number of elements to unpack.
///
/// - Returns: The unpacked values, in order.
///
/// - Throws: ``PackError`` if the source is exhausted, or the read would
/// pass the end of the innermost limited span.
///
	public mutating func unpack(_ type: Double.Type, count: Int) throws -> [Double] {
		try unpack(UInt64.self, count: count).map {
			Double(bitPattern: $0)
		}
	}

/// Unpack fixed width integers preceded by a count.
///
/// - Parameters:
///   - type: The type of integer to unpack.
///   - width: The width of the unsigned integer recording the element count.
///
/// - Returns: The unpacked values, in order.
///
/// - Throws: ``PackError`` if the source is exhausted, or the read would
/// pass the end of the innermost limited span.
///
	public mutating func unpack<T: PortableInteger>(
		_ type: T.Type,
		countPrefixedBy width: IntegerWidth
	) throws -> [T] {
		try unpack(type, count: try unpack(count: width))
	}

/// Unpack `Float` values preceded by a count.
///
/// - Parameters:
///   - type: The type of object to unpack.
///   - width: The width of the unsigned integer recording the element count.
///
/// - Returns: The unpacked values, in order.
///
/// - Throws: ``PackError`` if the source is exhausted, or the read would
/// pass the end of the innermost limited span.
///
	public mutating func unpack(
		_ type: Float.Type,
		countPrefixedBy width: IntegerWidth
	) throws -> [Float] {
		try unpack(type, count: try unpack(count: width))
	}

/// Unpack `Double` values preceded by a count.
///
/// - Parameters:
///   - type: The type of object to unpack.
///   - width: The width of the unsigned integer recording the element count.
///
/// - Returns: The unpacked values, in order.
///
/// - Throws: ``PackError`` if the source is exhausted, or the read would
/// pass the end of the innermost limited span.
///
	public mutating func unpack(
		_ type: Double.Type,
		countPrefixedBy width: IntegerWidth
	) throws -> [Double] {
		try unpack(type, count: try unpack(count: width))
	}

/// Unpack a span of a known length, ignoring anything within it that is not
/// read.
///
/// This is what allows a reader to accept a span written by a newer writer
/// that appended fields it does not recognise: the fields it knows about are
/// read, and the remainder is skipped.
///
/// ```swift
/// let length = try unpacker.unpack(UInt64.self)
/// try unpacker.withLimit(byteCount: Int(length)) { unpacker in
///     // read the fields this version knows about
/// }
/// ```
///
/// Reads inside the span are bounded as they happen, so a corrupt length
/// cannot be used to read on into whatever follows.
///
/// - Parameters:
///   - byteCount: The length of the span, measured from the current
///   position.
///   - body: A closure unpacking the contents of the span.
///
/// - Returns: The value returned by `body`.
///
/// - Throws: ``PackError`` if the span extends beyond an enclosing limit or
/// the end of the source, or if unpacking fails.
///
	@discardableResult
	public mutating func withLimit<R>(
		byteCount: Int,
		_ body: (inout Self) throws -> R
	) throws -> R {
		try pushLimit(byteCount: byteCount)

		let result: R
		do {
			result = try body(&self)
		}
		catch {
			// The limit is removed without skipping, so that the position
			// reflects where the failure occurred.
			//
			try? popLimit(skippingRemainder: false)
			throw error
		}

		try popLimit(skippingRemainder: true)
		return result
	}

// Unpacks a count written at the given width.
//
	private mutating func unpack(count width: IntegerWidth) throws -> Int {
		let value: UInt64
		switch width {
			case .uint8:
				value = UInt64(try unpack(UInt8.self))
			case .uint16:
				value = UInt64(try unpack(UInt16.self))
			case .uint32:
				value = UInt64(try unpack(UInt32.self))
			case .uint64:
				value = try unpack(UInt64.self)
		}

		guard value <= UInt64(Int.max) else {
			throw PackError(
				.valueOutOfRange,
				offset: unpackedCount,
				reason: "A count of \(value) cannot be represented on this platform"
			)
		}

		return Int(value)
	}
}

// As with packing, architecture dependent integers are a compile error rather
// than a documented hazard. See `Packer+Packing` for how the block works.
//
extension Unpacker {
	@available(*, unavailable, message: "Int is architecture-dependent and would read a file written only by a machine of matching width. Widen explicitly: Int(try unpack(Int64.self))")
	public mutating func unpack(_ type: Int.Type) throws -> Int {
		fatalError("unavailable")
	}

	@available(*, unavailable, message: "UInt is architecture-dependent and would read a file written only by a machine of matching width. Widen explicitly: UInt(try unpack(UInt64.self))")
	public mutating func unpack(_ type: UInt.Type) throws -> UInt {
		fatalError("unavailable")
	}

	@available(*, unavailable, message: "Int is architecture-dependent and would read a file written only by a machine of matching width. Read a sized type and map: try unpack(Int64.self, count: count).map(Int.init)")
	public mutating func unpack(_ type: Int.Type, count: Int) throws -> [Int] {
		fatalError("unavailable")
	}

	@available(*, unavailable, message: "UInt is architecture-dependent and would read a file written only by a machine of matching width. Read a sized type and map: try unpack(UInt64.self, count: count).map(UInt.init)")
	public mutating func unpack(_ type: UInt.Type, count: Int) throws -> [UInt] {
		fatalError("unavailable")
	}

	@available(*, unavailable, message: "Int is architecture-dependent and would read a file written only by a machine of matching width. Read a sized type and map: try unpack(Int64.self, countPrefixedBy: width).map(Int.init)")
	public mutating func unpack(_ type: Int.Type, countPrefixedBy width: IntegerWidth) throws -> [Int] {
		fatalError("unavailable")
	}

	@available(*, unavailable, message: "UInt is architecture-dependent and would read a file written only by a machine of matching width. Read a sized type and map: try unpack(UInt64.self, countPrefixedBy: width).map(UInt.init)")
	public mutating func unpack(_ type: UInt.Type, countPrefixedBy width: IntegerWidth) throws -> [UInt] {
		fatalError("unavailable")
	}
}
