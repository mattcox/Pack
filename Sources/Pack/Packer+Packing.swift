//
//  Packer+Packing.swift
//  Pack
//
//  Created by Matt Cox on 03/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Foundation

// The packing API. None of this is a protocol requirement - it is defined once
// here and shared by every packer, so that the encoding rules exist in exactly
// one place and the required surface stays small and non-generic.
//
extension Packer {
/// Pack a fixed width integer into the packer.
///
/// The value is written in the byte order named by the packer's
/// ``PackConfiguration``.
///
/// - Parameters:
///   - value: The integer to pack.
///
/// - Throws: ``PackError`` if the destination could not accept the bytes.
///
	public mutating func pack<T: PortableInteger>(_ value: T) throws {
		try packInteger(value)
	}

// The implementation behind every integer entry point. The public overloads
// forward here rather than to each other, so that the concrete overloads below
// cannot recurse into themselves.
//
	private mutating func packInteger<T: FixedWidthInteger>(_ value: T) throws {
		let ordered = configuration.byteOrder == .littleEndian ? value.littleEndian : value.bigEndian
		try withUnsafeBytes(of: ordered) {
			try write($0)
		}
	}

// The sized integer types conform to Packable as well as FixedWidthInteger, so
// a call such as `pack(someInt32)` matches two generic entry points, and
// neither is more specialised than the other. These concrete overloads settle
// it: being concrete, they are more specific than either.
//
// They are conveniences rather than protocol requirements, so the required
// surface stays non-generic and small - see ``Packer``.
//
	public mutating func pack(_ value: Int8) throws {
		try packInteger(value)
	}

	public mutating func pack(_ value: Int16) throws {
		try packInteger(value)
	}

	public mutating func pack(_ value: Int32) throws {
		try packInteger(value)
	}

	public mutating func pack(_ value: Int64) throws {
		try packInteger(value)
	}

	public mutating func pack(_ value: UInt8) throws {
		try packInteger(value)
	}

	public mutating func pack(_ value: UInt16) throws {
		try packInteger(value)
	}

	public mutating func pack(_ value: UInt32) throws {
		try packInteger(value)
	}

	public mutating func pack(_ value: UInt64) throws {
		try packInteger(value)
	}

/// Pack a `Bool` into the packer, as a single byte.
///
/// - Parameters:
///   - value: The `Bool` to pack.
///
/// - Throws: ``PackError`` if the destination could not accept the bytes.
///
	public mutating func pack(_ value: Bool) throws {
		try pack(value ? UInt8(1) : UInt8(0))
	}

/// Pack a `Float` into the packer, as its 32-bit bit pattern.
///
/// - Parameters:
///   - value: The `Float` to pack.
///
/// - Throws: ``PackError`` if the destination could not accept the bytes.
///
	public mutating func pack(_ value: Float) throws {
		try pack(value.bitPattern)
	}

/// Pack a `Double` into the packer, as its 64-bit bit pattern.
///
/// - Parameters:
///   - value: The `Double` to pack.
///
/// - Throws: ``PackError`` if the destination could not accept the bytes.
///
	public mutating func pack(_ value: Double) throws {
		try pack(value.bitPattern)
	}

/// Pack bytes stored in a `Data` object into the packer.
///
/// The bytes are written exactly as given, and are not reordered.
///
/// - Parameters:
///   - data: The `Data` containing the bytes to pack.
///
/// - Throws: ``PackError`` if the destination could not accept the bytes.
///
	public mutating func pack(_ data: Data) throws {
		guard !data.isEmpty else {
			return
		}

		try data.withUnsafeBytes {
			try write($0)
		}
	}

/// Pack a type conforming to ``Packable`` into the packer.
///
/// - Parameters:
///   - value: The value to pack.
///
/// - Throws: ``PackError`` if the value could not be packed.
///
	public mutating func pack<T: Packable>(_ value: T) throws {
		try value.pack(to: &self)
	}

/// Pack a `String` into the packer.
///
/// The byte order named by the packer's ``PackConfiguration`` is not applied
/// to string data. Where a specific byte order is required, use the
/// corresponding encoding, such as `utf16BigEndian`.
///
/// - Parameters:
///   - value: The `String` to pack.
///   - encoding: The encoding used to convert the string to bytes. Defaults
///   to the encoding named by the packer's configuration.
///   - framing: How the extent of the string is recorded. Defaults to the
///   framing named by the packer's configuration.
///
/// - Throws: ``PackError`` if the string cannot be represented in the given
/// encoding, if the encoding and framing are incompatible, or if the string
/// does not fit a fixed size field.
///
	public mutating func pack(
		_ value: String,
		using encoding: String.Encoding? = nil,
		framing: StringFraming? = nil
	) throws {
		let encoding = encoding ?? configuration.defaultStringEncoding
		let framing = framing ?? configuration.defaultStringFraming

		guard let data = value.data(using: encoding) else {
			throw PackError(
				.invalidString,
				offset: packedCount,
				reason: "The string could not be represented in the requested encoding"
			)
		}

		switch framing {
			case .lengthPrefixed(let width):
				try pack(count: data.count, width: width, describing: "string")
				try pack(data)

			case .nullTerminated:
				guard encoding == .ascii || encoding == .utf8 else {
					throw PackError(
						.unsupportedEncoding,
						offset: packedCount,
						reason: "Only ascii and utf8 strings may be null terminated"
					)
				}

				guard !data.contains(.zero) else {
					throw PackError(
						.invalidString,
						offset: packedCount,
						reason: "A null terminated string may not contain a null character"
					)
				}

				try pack(data)
				try pack(UInt8.zero)

			case .fixed(let byteCount, let padding):
				guard data.count <= byteCount else {
					throw PackError(
						.valueOutOfRange,
						offset: packedCount,
						reason: "The string occupies \(data.count) bytes, which exceeds the \(byteCount) byte field"
					)
				}

				try pack(data)

				if data.count < byteCount {
					let bytes = [UInt8](repeating: padding, count: byteCount - data.count)
					try bytes.withUnsafeBytes {
						try write($0)
					}
				}

			case .untilEnd:
				try pack(data)
		}
	}

/// Pack the elements of a collection of fixed width integers.
///
/// Nothing is written to describe how many elements there are. Use
/// `pack(contentsOf:countPrefixedBy:)` where the count must be recoverable.
///
/// - Parameters:
///   - values: The values to pack, in order.
///
/// - Throws: ``PackError`` if the destination could not accept the bytes.
///
	public mutating func pack<C: Collection>(contentsOf values: C) throws where C.Element: PortableInteger {
		// Where no reordering is required the elements are already laid out
		// correctly in memory, so contiguous storage can be handed over whole.
		//
		if MemoryLayout<C.Element>.size == 1 || configuration.byteOrder == ByteOrder.system {
			let packed = try values.withContiguousStorageIfAvailable { buffer in
				try write(UnsafeRawBufferPointer(buffer))
				return true
			}

			if packed == true {
				return
			}
		}

		for value in values {
			try pack(value)
		}
	}

/// Pack the elements of a collection of `Float` values.
///
/// - Parameters:
///   - values: The values to pack, in order.
///
/// - Throws: ``PackError`` if the destination could not accept the bytes.
///
	public mutating func pack<C: Collection>(contentsOf values: C) throws where C.Element == Float {
		if configuration.byteOrder == ByteOrder.system {
			let packed = try values.withContiguousStorageIfAvailable { buffer in
				try write(UnsafeRawBufferPointer(buffer))
				return true
			}

			if packed == true {
				return
			}
		}

		for value in values {
			try pack(value)
		}
	}

/// Pack the elements of a collection of `Double` values.
///
/// - Parameters:
///   - values: The values to pack, in order.
///
/// - Throws: ``PackError`` if the destination could not accept the bytes.
///
	public mutating func pack<C: Collection>(contentsOf values: C) throws where C.Element == Double {
		if configuration.byteOrder == ByteOrder.system {
			let packed = try values.withContiguousStorageIfAvailable { buffer in
				try write(UnsafeRawBufferPointer(buffer))
				return true
			}

			if packed == true {
				return
			}
		}

		for value in values {
			try pack(value)
		}
	}

/// Pack the elements of a collection of fixed width integers, preceded by
/// the number of elements.
///
/// - Parameters:
///   - values: The values to pack, in order.
///   - width: The width of the unsigned integer recording the element count.
///
/// - Throws: ``PackError`` if the count does not fit the given width, or if
/// the destination could not accept the bytes.
///
	public mutating func pack<C: Collection>(
		contentsOf values: C,
		countPrefixedBy width: IntegerWidth
	) throws where C.Element: PortableInteger {
		try pack(count: values.count, width: width, describing: "collection")
		try pack(contentsOf: values)
	}

/// Pack the elements of a collection of `Float` values, preceded by the
/// number of elements.
///
/// - Parameters:
///   - values: The values to pack, in order.
///   - width: The width of the unsigned integer recording the element count.
///
/// - Throws: ``PackError`` if the count does not fit the given width, or if
/// the destination could not accept the bytes.
///
	public mutating func pack<C: Collection>(
		contentsOf values: C,
		countPrefixedBy width: IntegerWidth
	) throws where C.Element == Float {
		try pack(count: values.count, width: width, describing: "collection")
		try pack(contentsOf: values)
	}

/// Pack the elements of a collection of `Double` values, preceded by the
/// number of elements.
///
/// - Parameters:
///   - values: The values to pack, in order.
///   - width: The width of the unsigned integer recording the element count.
///
/// - Throws: ``PackError`` if the count does not fit the given width, or if
/// the destination could not accept the bytes.
///
	public mutating func pack<C: Collection>(
		contentsOf values: C,
		countPrefixedBy width: IntegerWidth
	) throws where C.Element == Double {
		try pack(count: values.count, width: width, describing: "collection")
		try pack(contentsOf: values)
	}

/// Assert that packing is complete.
///
/// A reserved slot that is never filled leaves the output structurally
/// invalid, and neither destination can report that on its own: a patchable
/// destination leaves the slot as zeroes, and a buffering destination never
/// writes the span at all. Call this once packing is done, and treat the
/// output as unusable if it throws.
///
/// ```swift
/// try packer.pack(document)
/// try packer.finish()
///
/// let data = packer.data
/// ```
///
/// - Throws: ``PackError`` with code `incompleteOutput` if any reserved slot
/// has not been filled.
///
	public func finish() throws {
		guard !hasOpenPlaceholders else {
			throw PackError(
				.incompleteOutput,
				offset: packedCount,
				reason: "Packing ended with a reserved slot still unfilled, so the output is incomplete"
			)
		}
	}

/// Reserve a fixed width integer to be filled in later.
///
/// - Parameters:
///   - type: The type of integer to reserve space for.
///
/// - Returns: A placeholder identifying the reserved bytes.
///
/// - Throws: ``PackError`` if the bytes could not be reserved.
///
	public mutating func reserve<T: PortableInteger>(_ type: T.Type) throws -> PackerPlaceholder {
		try reserve(byteCount: MemoryLayout<T>.size)
	}

/// Fill a previously reserved fixed width integer.
///
/// - Parameters:
///   - placeholder: The placeholder identifying the reserved bytes.
///   - value: The value to write into the reserved slot.
///
/// - Throws: ``PackError`` if the placeholder does not belong to this
/// packer, was already filled, or if the value does not match the reserved
/// width.
///
	public mutating func fill<T: PortableInteger>(_ placeholder: PackerPlaceholder, with value: T) throws {
		guard MemoryLayout<T>.size == placeholder.byteCount else {
			throw PackError(
				.valueOutOfRange,
				offset: placeholder.offset,
				reason: "A \(MemoryLayout<T>.size) byte value cannot fill a \(placeholder.byteCount) byte placeholder"
			)
		}

		let ordered = configuration.byteOrder == .littleEndian ? value.littleEndian : value.bigEndian
		try withUnsafeBytes(of: ordered) {
			try fill(placeholder, with: $0)
		}
	}

/// Pack a span, preceded by its length in bytes.
///
/// This is the intended way to frame a body whose size is not known until it
/// has been packed. The length is reserved, the body is packed, and the
/// length is filled in afterwards.
///
/// ```swift
/// try packer.pack(tag, using: .ascii, framing: .fixed(byteCount: 4))
/// try packer.withLengthPrefix(.uint64) { packer in
///     try packer.pack(mesh)
/// }
/// ```
///
/// The bytes produced do not depend on whether the packer can patch its
/// output in place. A packer writing to a stream buffers the body until the
/// length is known; a packer writing to memory patches the length directly.
/// Both produce the same file.
///
/// - Warning: If `body` throws, the span is left open and its length is
/// never written. The output is incomplete from that point on - a buffering
/// destination will not have received the span at all, and will silently
/// swallow anything packed after it. Call ``finish()`` before using the
/// output, which reports that state as an error.
///
/// - Parameters:
///   - width: The width of the unsigned integer recording the byte count.
///   Prefer `.uint64` for a binary payload, which can exceed the 4 GB
///   ceiling imposed by `.uint32`.
///   - body: A closure packing the contents of the span.
///
/// - Returns: The value returned by `body`.
///
/// - Throws: ``PackError`` if the span's length does not fit the given
/// width, or if packing fails.
///
	@discardableResult
	public mutating func withLengthPrefix<R>(
		_ width: IntegerWidth,
		_ body: (inout Self) throws -> R
	) throws -> R {
		let placeholder = try reserve(byteCount: width.byteCount)
		let start = packedCount

		let result = try body(&self)

		let length = packedCount - start
		guard UInt64(length) <= width.maximumValue else {
			throw PackError(
				.valueOutOfRange,
				offset: placeholder.offset,
				reason: "A span of \(length) bytes cannot be described by a \(width.byteCount) byte length"
			)
		}

		switch width {
			case .uint8:
				try fill(placeholder, with: UInt8(length))
			case .uint16:
				try fill(placeholder, with: UInt16(length))
			case .uint32:
				try fill(placeholder, with: UInt32(length))
			case .uint64:
				try fill(placeholder, with: UInt64(length))
		}

		return result
	}

// Packs a count at the given width, reporting a value that does not fit in
// terms of what was being counted.
//
	private mutating func pack(count: Int, width: IntegerWidth, describing subject: String) throws {
		guard count >= 0, UInt64(count) <= width.maximumValue else {
			throw PackError(
				.valueOutOfRange,
				offset: packedCount,
				reason: "A \(subject) of \(count) cannot be described by a \(width.byteCount) byte count"
			)
		}

		switch width {
			case .uint8:
				try pack(UInt8(count))
			case .uint16:
				try pack(UInt16(count))
			case .uint32:
				try pack(UInt32(count))
			case .uint64:
				try pack(UInt64(count))
		}
	}
}

// Architecture dependent integers are blocked at the call site rather than
// warned about in documentation.
//
// The block itself comes from ``PortableInteger``, which Int and UInt do not
// conform to. These unavailable overloads exist to turn the conformance failure
// into a message that says what to do instead.
//
extension Packer {
	@available(*, unavailable, message: "Int is architecture-dependent and would produce a file readable only on the machine that wrote it. Widen explicitly: pack(Int64(value))")
	public mutating func pack(_ value: Int) throws {
		fatalError("unavailable")
	}

	@available(*, unavailable, message: "UInt is architecture-dependent and would produce a file readable only on the machine that wrote it. Widen explicitly: pack(UInt64(value))")
	public mutating func pack(_ value: UInt) throws {
		fatalError("unavailable")
	}

	@available(*, unavailable, message: "Int is architecture-dependent and would produce a file readable only on the machine that wrote it. Map to a sized type first: pack(contentsOf: values.map(Int64.init))")
	public mutating func pack<C: Collection>(contentsOf values: C) throws where C.Element == Int {
		fatalError("unavailable")
	}

	@available(*, unavailable, message: "UInt is architecture-dependent and would produce a file readable only on the machine that wrote it. Map to a sized type first: pack(contentsOf: values.map(UInt64.init))")
	public mutating func pack<C: Collection>(contentsOf values: C) throws where C.Element == UInt {
		fatalError("unavailable")
	}

	@available(*, unavailable, message: "Int is architecture-dependent and would produce a file readable only on the machine that wrote it. Map to a sized type first: pack(contentsOf: values.map(Int64.init), countPrefixedBy: width)")
	public mutating func pack<C: Collection>(
		contentsOf values: C,
		countPrefixedBy width: IntegerWidth
	) throws where C.Element == Int {
		fatalError("unavailable")
	}

	@available(*, unavailable, message: "UInt is architecture-dependent and would produce a file readable only on the machine that wrote it. Map to a sized type first: pack(contentsOf: values.map(UInt64.init), countPrefixedBy: width)")
	public mutating func pack<C: Collection>(
		contentsOf values: C,
		countPrefixedBy width: IntegerWidth
	) throws where C.Element == UInt {
		fatalError("unavailable")
	}
}
