//
//  DataDestination.swift
//  Pack
//
//  Created by Matt Cox on 03/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Foundation

/// A ``PackDestination`` that accumulates packed bytes in memory.
///
/// This destination can revise bytes already written, so a packer using it
/// fills reserved slots directly and never buffers.
///
public struct DataDestination: PackDestination {
/// The bytes held by this destination, including any it was seeded with.
///
	public private(set) var data: Data

// Where this destination's own output begins. A packer counts from zero and
// its placeholder offsets are relative to itself, so anything the destination
// was seeded with has to be added back before touching `data`.
//
	private let baseOffset: Int

/// Initialize a new destination.
///
/// - Parameters:
///   - data: Bytes already written, which packed bytes are appended after.
///   Defaults to empty. These are preserved, are not counted by
///   ``DataDestination/count``, and are never overwritten by a patch.
///
	public init(_ data: Data = Data()) {
		self.data = data
		self.baseOffset = data.count
	}

/// The number of bytes packed into this destination.
///
/// This counts only what was packed, not anything the destination was seeded
/// with, so it agrees with ``Packer/packedCount``.
///
	public var count: Int {
		data.count - baseOffset
	}

	public var patchesInPlace: Bool {
		true
	}

	public mutating func write(_ bytes: UnsafeRawBufferPointer) throws {
		guard let baseAddress = bytes.baseAddress, !bytes.isEmpty else {
			return
		}

		data.append(baseAddress.assumingMemoryBound(to: UInt8.self), count: bytes.count)
	}

	public mutating func patch(at offset: Int, with bytes: UnsafeRawBufferPointer) throws {
		guard offset >= 0, offset + bytes.count <= count else {
			throw PackError(
				.destinationFailure,
				offset: offset,
				reason: "The range being patched lies outside the bytes written so far"
			)
		}

		guard !bytes.isEmpty else {
			return
		}

		let start = data.startIndex + baseOffset + offset
		data.replaceSubrange(start..<(start + bytes.count), with: bytes)
	}

/// Reserve capacity for the given number of bytes, to avoid reallocating
/// while packing a body of known size.
///
/// - Parameters:
///   - byteCount: The number of bytes to reserve capacity for.
///
	public mutating func reserveCapacity(_ byteCount: Int) {
		data.reserveCapacity(byteCount)
	}
}
