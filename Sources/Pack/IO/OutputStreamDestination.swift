//
//  OutputStreamDestination.swift
//  Pack
//
//  Created by Matt Cox on 03/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Foundation

/// A ``PackDestination`` that writes packed bytes to an `OutputStream`.
///
/// Bytes handed to a stream cannot be revised, so a packer using this
/// destination buffers the body of a reserved span in memory until the slot is
/// filled. The bytes produced are identical to those a ``DataDestination``
/// would produce for the same calls.
///
public struct OutputStreamDestination: PackDestination {
	private let stream: OutputStream

/// The number of bytes written to the stream.
///
	public private(set) var count: Int = 0

/// Initialize a new destination.
///
/// - Parameters:
///   - stream: The stream to write to. The stream must already be open.
///
	public init(_ stream: OutputStream) {
		self.stream = stream
	}

	public var patchesInPlace: Bool {
		false
	}

	public mutating func write(_ bytes: UnsafeRawBufferPointer) throws {
		guard let baseAddress = bytes.baseAddress, !bytes.isEmpty else {
			return
		}

		var pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
		var remaining = bytes.count

		// A stream is free to accept less than it was offered, so writing
		// continues until everything has been handed over.
		//
		while remaining > 0 {
			let written = stream.write(pointer, maxLength: remaining)

			if written > 0 {
				pointer += written
				remaining -= written
				count += written
				continue
			}

			if written == 0 {
				throw PackError(
					.destinationFailure,
					offset: count,
					reason: "The stream reached its capacity"
				)
			}

			switch stream.streamStatus {
				case .notOpen:
					throw PackError(.destinationFailure, offset: count, reason: "The stream is not open")
				case .closed:
					throw PackError(.destinationFailure, offset: count, reason: "The stream has been closed")
				default:
					throw PackError(
						.destinationFailure,
						offset: count,
						reason: "The stream failed to accept the data",
						underlying: stream.streamError
					)
			}
		}
	}

	public mutating func patch(at offset: Int, with bytes: UnsafeRawBufferPointer) throws {
		throw PackError(
			.unsupportedOperation,
			offset: offset,
			reason: "A stream cannot revise bytes it has already been given"
		)
	}
}
