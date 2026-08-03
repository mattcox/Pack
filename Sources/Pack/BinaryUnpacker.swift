//
//  BinaryUnpacker.swift
//  Pack
//
//  Created by Matt Cox on 01/02/2022.
//  Copyright © 2024 Matt Cox. All rights reserved.
//

import Foundation

/// An ``Unpacker`` that unpacks values from raw binary data.
///
/// ```swift
/// var unpacker = BinaryUnpacker(from: data, configuration: .littleEndian)
/// let count = try unpacker.unpack(Int64.self)
/// let scale = try unpacker.unpack(Double.self)
/// let name = try unpacker.unpack(String.self)
/// ```
///
/// Where the input is framed into spans, ``Unpacker/withLimit(byteCount:_:)``
/// bounds reads to the current span, so that a length which does not match its
/// contents is reported rather than allowed to run on into what follows.
///
public final class BinaryUnpacker<Source: UnpackSource>: Unpacker {
/// The layout rules this unpacker applies.
///
	public let configuration: PackConfiguration

/// The user info for storing local data associated with the current unpack.
///
	public var userInfo: [PackUserInfoKey: any Sendable] = [:]

/// The source unpacked bytes are read from.
///
	public private(set) var source: Source

// Absolute offsets at which the innermost and enclosing spans end.
//
	private var limits: [Int] = []

/// Initialize a new unpacker.
///
/// - Parameters:
///   - source: The source to read bytes from.
///   - configuration: The layout rules to apply.
///
	public init(source: Source, configuration: PackConfiguration) {
		self.source = source
		self.configuration = configuration
	}

	public var unpackedCount: Int {
		source.consumedCount
	}

	public var remainingCount: Int? {
		guard let limit = limits.last else {
			return source.remainingCount
		}

		let withinSpan = limit - unpackedCount

		guard let withinSource = source.remainingCount else {
			return withinSpan
		}

		return Swift.min(withinSpan, withinSource)
	}

/// How many spans are currently bounded by a limit.
///
	public var limitDepth: Int {
		limits.count
	}

	public func read(into buffer: UnsafeMutableRawBufferPointer) throws {
		guard !buffer.isEmpty else {
			return
		}

		try check(byteCount: buffer.count)
		try source.read(into: buffer)
	}

	public func skip(_ byteCount: Int) throws {
		guard byteCount > 0 else {
			return
		}

		try check(byteCount: byteCount)
		try source.skip(byteCount)
	}

	public func pushLimit(byteCount: Int) throws {
		guard byteCount >= 0 else {
			throw PackError(
				.valueOutOfRange,
				offset: unpackedCount,
				reason: "A span cannot be \(byteCount) bytes long"
			)
		}

		// A span is checked against its surroundings when it opens, rather
		// than leaving a length that could never be valid to fail somewhere
		// less obvious later on.
		//
		try check(byteCount: byteCount)

		if let remaining = source.remainingCount, byteCount > remaining {
			throw PackError(
				.endOfInput,
				offset: unpackedCount,
				reason: "A span of \(byteCount) bytes extends beyond the \(remaining) bytes remaining"
			)
		}

		limits.append(unpackedCount + byteCount)
	}

	public func popLimit(skippingRemainder: Bool) throws {
		guard let limit = limits.popLast() else {
			throw PackError(
				.unsupportedOperation,
				offset: unpackedCount,
				reason: "There is no span to close"
			)
		}

		guard skippingRemainder else {
			return
		}

		let remainder = limit - unpackedCount

		guard remainder >= 0 else {
			throw PackError(
				.overrun,
				offset: unpackedCount,
				reason: "The span's contents extended \(-remainder) bytes beyond its declared length"
			)
		}

		// The limit has already been removed, so this skips against whatever
		// span encloses it - which the limit was checked to sit within.
		//
		if remainder > 0 {
			try source.skip(remainder)
		}
	}

// Checks that reading the given number of bytes stays within the innermost
// span, where there is one.
//
	private func check(byteCount: Int) throws {
		guard let limit = limits.last else {
			return
		}

		guard unpackedCount + byteCount <= limit else {
			throw PackError(
				.overrun,
				offset: unpackedCount,
				reason: "Reading \(byteCount) bytes would pass the end of the span, \(limit - unpackedCount) bytes away"
			)
		}
	}
}

extension BinaryUnpacker where Source == DataSource {
/// Initialize a new unpacker, reading from bytes held in memory.
///
/// - Parameters:
///   - data: The bytes to unpack from.
///   - configuration: The layout rules to apply.
///
	public convenience init(from data: Data, configuration: PackConfiguration) {
		self.init(source: DataSource(data), configuration: configuration)
	}
}

extension BinaryUnpacker where Source == InputStreamSource {
/// Initialize a new unpacker, reading from a stream.
///
/// - Parameters:
///   - stream: The stream to read from. The stream must already be open.
///   - configuration: The layout rules to apply.
///
	public convenience init(readingFrom stream: InputStream, configuration: PackConfiguration) {
		self.init(source: InputStreamSource(stream), configuration: configuration)
	}
}
