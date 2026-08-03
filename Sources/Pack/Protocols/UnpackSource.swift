//
//  UnpackSource.swift
//  Pack
//
//  Created by Matt Cox on 03/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

/// A source that packed bytes are read from.
///
public protocol UnpackSource {
/// The number of bytes consumed from this source.
///
	var consumedCount: Int { get }

/// The number of bytes remaining, or `nil` where that cannot be known.
///
/// A source of indeterminate length, such as one wrapping a stream, reports
/// `nil`.
///
	var remainingCount: Int? { get }

/// Read bytes from the source, filling the given buffer completely.
///
/// - Parameters:
///   - buffer: The buffer to fill.
///
/// - Throws: ``PackError`` if the source is exhausted before the buffer is
/// filled.
///
	mutating func read(into buffer: UnsafeMutableRawBufferPointer) throws

/// Advance past the specified number of bytes.
///
/// - Parameters:
///   - byteCount: The number of bytes to skip.
///
/// - Throws: ``PackError`` if the source is exhausted first.
///
	mutating func skip(_ byteCount: Int) throws
}
