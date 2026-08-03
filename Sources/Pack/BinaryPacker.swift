//
//  BinaryPacker.swift
//  Pack
//
//  Created by Matt Cox on 01/02/2022.
//  Copyright © 2024 Matt Cox. All rights reserved.
//

import Foundation

/// A ``Packer`` that packs values as raw binary data.
///
/// BinaryPacker writes primitive values as 8-bit aligned bytes with nothing
/// between them - an `Int8` and an `Int16` packed in sequence carry no marker
/// indicating where one ends and the next begins. It is up to the caller to
/// describe a layout that can be read back.
///
/// ```swift
/// var packer = BinaryPacker(configuration: .littleEndian)
/// try packer.pack(Int64(12345))
/// try packer.pack(6789.0)
/// try packer.pack("Hello, world!")
///
/// let data = packer.data
/// ```
///
/// - Note: The packing API is declared `mutating`, so that packers which are
/// value types remain possible. A BinaryPacker is a reference type, but must
/// still be held in a `var` for those methods to be callable.
///
/// Where a span must record its own length, use
/// ``Packer/withLengthPrefix(_:_:)``. This works whatever the destination: a
/// packer writing to memory patches the length in place, and a packer writing
/// to a stream buffers the body until the length is known. Both produce the
/// same bytes.
///
public final class BinaryPacker<Destination: PackDestination>: Packer {
/// The layout rules this packer applies.
///
	public let configuration: PackConfiguration

/// The user info for storing local data associated with the current pack.
///
	public var userInfo: [PackUserInfoKey: any Sendable] = [:]

/// The destination packed bytes are written to.
///
	public private(set) var destination: Destination

/// How many bytes have been packed so far.
///
	public private(set) var packedCount: Int = 0

	private let identity = PackerIdentity()
	private var nextToken: UInt64 = 0
	private var openTokens: Set<UInt64> = []
	private var spans: [Span] = []

// A span whose length is not yet known, buffered because the destination
// cannot revise what it has already been given.
//
	private struct Span {
		let token: UInt64
		var value: [UInt8]?
		var buffer: [UInt8]
	}

/// Initialize a new packer.
///
/// - Parameters:
///   - destination: The destination to write packed bytes to.
///   - configuration: The layout rules to apply.
///
	public init(destination: Destination, configuration: PackConfiguration) {
		self.destination = destination
		self.configuration = configuration
	}

	public var patchesInPlace: Bool {
		destination.patchesInPlace
	}

/// Whether any reserved slot has yet to be filled.
///
/// Packed output is only complete once this is `false`. An unfilled slot
/// left in a patchable destination reads as zeroes; an unfilled slot in a
/// buffering destination means its span has not been written at all.
///
	public var hasOpenPlaceholders: Bool {
		!openTokens.isEmpty
	}

	public func write(_ bytes: UnsafeRawBufferPointer) throws {
		guard !bytes.isEmpty else {
			return
		}

		try emit(bytes)
		packedCount += bytes.count
	}

	public func reserve(byteCount: Int) throws -> PackerPlaceholder {
		guard byteCount > 0 else {
			throw PackError(
				.valueOutOfRange,
				offset: packedCount,
				reason: "Cannot reserve \(byteCount) bytes"
			)
		}

		let token = nextToken
		nextToken += 1
		openTokens.insert(token)

		let offset = packedCount

		if destination.patchesInPlace {
			// The slot is written out as zeroes now and revised later, so
			// nothing needs to be held in memory.
			//
			let placeholder = [UInt8](repeating: .zero, count: byteCount)
			try placeholder.withUnsafeBytes { bytes in
				try emit(bytes)
			}
		}
		else {
			// The destination has already handed on everything written so
			// far, so the body of this span is buffered until its length is
			// known. Nesting is handled by stacking buffers.
			//
			spans.append(Span(token: token, value: nil, buffer: []))
		}

		packedCount += byteCount

		return PackerPlaceholder(owner: identity, token: token, offset: offset, byteCount: byteCount)
	}

	public func fill(_ placeholder: PackerPlaceholder, with bytes: UnsafeRawBufferPointer) throws {
		guard placeholder.isOwned(by: identity) else {
			throw PackError(
				.invalidPlaceholder,
				offset: placeholder.offset,
				reason: "The placeholder was not created by this packer"
			)
		}

		guard bytes.count == placeholder.byteCount else {
			throw PackError(
				.valueOutOfRange,
				offset: placeholder.offset,
				reason: "\(bytes.count) bytes cannot fill a \(placeholder.byteCount) byte placeholder"
			)
		}

		guard openTokens.contains(placeholder.token) else {
			throw PackError(
				.placeholderAlreadyFilled,
				offset: placeholder.offset,
				reason: "The placeholder has already been filled"
			)
		}

		if destination.patchesInPlace {
			try destination.patch(at: placeholder.offset, with: bytes)
			openTokens.remove(placeholder.token)
			return
		}

		// The slot cannot be revised once written, so the value is recorded
		// against its span and the span is held until everything preceding it
		// is resolved. Spans may be filled in any order, exactly as they may
		// be on a destination that patches - only how long the bytes are held
		// in memory differs.
		//
		guard let index = spans.firstIndex(where: { $0.token == placeholder.token }) else {
			throw PackError(
				.invalidPlaceholder,
				offset: placeholder.offset,
				reason: "The placeholder does not correspond to an open span"
			)
		}

		spans[index].value = Array(bytes)
		openTokens.remove(placeholder.token)

		try flushResolvedSpans()
	}

// Writes out every span at the bottom of the stack whose slot is now known.
//
// A span's bytes sit at a fixed position, so the outermost unresolved span
// blocks everything after it. Once its value arrives, it and any spans behind
// it that are already resolved can be handed to the destination in order.
//
	private func flushResolvedSpans() throws {
		while let span = spans.first, let value = span.value {
			spans.removeFirst()

			try value.withUnsafeBytes { bytes in
				try destination.write(bytes)
			}

			try span.buffer.withUnsafeBytes { bytes in
				try destination.write(bytes)
			}
		}
	}

// Writes bytes to the innermost open span, or to the destination when there
// is none. This does not advance `packedCount`, so that flushing a buffered
// span does not count its bytes a second time.
//
	private func emit(_ bytes: UnsafeRawBufferPointer) throws {
		guard !bytes.isEmpty else {
			return
		}

		if spans.isEmpty {
			try destination.write(bytes)
		}
		else {
			spans[spans.count - 1].buffer.append(contentsOf: bytes)
		}
	}
}

extension BinaryPacker where Destination == DataDestination {
/// Initialize a new packer, accumulating packed bytes in memory.
///
/// - Parameters:
///   - configuration: The layout rules to apply.
///
	public convenience init(configuration: PackConfiguration) {
		self.init(destination: DataDestination(), configuration: configuration)
	}

/// The packed bytes, including any the destination was seeded with.
///
/// - Warning: Any slot reserved and not yet filled reads as zeroes. Call
/// ``Packer/finish()`` before using this, which reports that as an error.
///
	public var data: Data {
		destination.data
	}
}

extension BinaryPacker where Destination == OutputStreamDestination {
/// Initialize a new packer, writing packed bytes to a stream.
///
/// - Parameters:
///   - stream: The stream to write to. The stream must already be open.
///   - configuration: The layout rules to apply.
///
	public convenience init(writingTo stream: OutputStream, configuration: PackConfiguration) {
		self.init(destination: OutputStreamDestination(stream), configuration: configuration)
	}
}
