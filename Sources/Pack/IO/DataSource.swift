//
//  DataSource.swift
//  Pack
//
//  Created by Matt Cox on 03/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Foundation

/// An ``UnpackSource`` that reads from bytes held in memory.
///
public struct DataSource: UnpackSource {
	private let data: Data

/// The number of bytes consumed so far.
///
	public private(set) var consumedCount: Int = 0

/// Initialize a new source.
///
/// - Parameters:
///   - data: The bytes to unpack from.
///
	public init(_ data: Data) {
		self.data = data
	}

	public var remainingCount: Int? {
		data.count - consumedCount
	}

	public mutating func read(into buffer: UnsafeMutableRawBufferPointer) throws {
		guard !buffer.isEmpty else {
			return
		}

		let offset = consumedCount
		let byteCount = buffer.count

		guard offset + byteCount <= data.count else {
			throw PackError(
				.endOfInput,
				offset: offset,
				reason: "Requested \(byteCount) bytes, but only \(data.count - offset) remain"
			)
		}

		data.withUnsafeBytes { source in
			buffer.copyMemory(from: UnsafeRawBufferPointer(rebasing: source[offset..<(offset + byteCount)]))
		}

		consumedCount += byteCount
	}

	public mutating func skip(_ byteCount: Int) throws {
		guard byteCount > 0 else {
			return
		}

		guard consumedCount + byteCount <= data.count else {
			throw PackError(
				.endOfInput,
				offset: consumedCount,
				reason: "Cannot skip \(byteCount) bytes, as only \(data.count - consumedCount) remain"
			)
		}

		consumedCount += byteCount
	}
}
