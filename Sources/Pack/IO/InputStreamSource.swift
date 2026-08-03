//
//  InputStreamSource.swift
//  Pack
//
//  Created by Matt Cox on 03/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Foundation

/// An ``UnpackSource`` that reads from an `InputStream`.
///
/// The length of a stream is not knowable in advance, so
/// ``InputStreamSource/remainingCount`` is always `nil`.
///
public struct InputStreamSource: UnpackSource {
	private let stream: InputStream

/// The number of bytes consumed so far.
///
	public private(set) var consumedCount: Int = 0

/// Initialize a new source.
///
/// - Parameters:
///   - stream: The stream to unpack from. The stream must already be open.
///
	public init(_ stream: InputStream) {
		self.stream = stream
	}

	public var remainingCount: Int? {
		nil
	}

	public mutating func read(into buffer: UnsafeMutableRawBufferPointer) throws {
		guard let baseAddress = buffer.baseAddress, !buffer.isEmpty else {
			return
		}

		var pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
		var remaining = buffer.count

		// A stream is free to return less than was asked for, so reading
		// continues until the buffer is full.
		//
		while remaining > 0 {
			let read = stream.read(pointer, maxLength: remaining)

			if read > 0 {
				pointer += read
				remaining -= read
				consumedCount += read
				continue
			}

			if read == 0 {
				throw PackError(
					.endOfInput,
					offset: consumedCount,
					reason: "The stream ended with \(remaining) bytes still to read"
				)
			}

			switch stream.streamStatus {
				case .notOpen:
					throw PackError(.sourceFailure, offset: consumedCount, reason: "The stream is not open")
				case .closed:
					throw PackError(.sourceFailure, offset: consumedCount, reason: "The stream has been closed")
				default:
					throw PackError(
						.sourceFailure,
						offset: consumedCount,
						reason: "The stream failed to provide the data",
						underlying: stream.streamError
					)
			}
		}
	}

	public mutating func skip(_ byteCount: Int) throws {
		guard byteCount > 0 else {
			return
		}

		// A stream cannot seek, so skipped bytes are read and discarded.
		//
		var scratch = [UInt8](repeating: .zero, count: Swift.min(byteCount, 4096))
		var remaining = byteCount

		while remaining > 0 {
			let chunk = Swift.min(remaining, scratch.count)

			try scratch.withUnsafeMutableBytes { buffer in
				try read(into: UnsafeMutableRawBufferPointer(rebasing: buffer[0..<chunk]))
			}

			remaining -= chunk
		}
	}
}
