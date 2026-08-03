//
//  PackDestination.swift
//  Pack
//
//  Created by Matt Cox on 03/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

/// A sink that packed bytes are written into.
///
/// Separating the sink from the codec is what allows a single ``BinaryPacker``
/// implementation to serve memory, streams, and anything a client cares to add
/// - a memory mapped file, a socket, a compressing sink - without any of them
/// reimplementing how a value becomes bytes.
///
public protocol PackDestination {
/// The number of bytes written to this destination.
///
	var count: Int { get }

/// Whether bytes already written can be revised in place.
///
/// A destination that has handed its output onwards, such as one wrapping a
/// stream, cannot. ``BinaryPacker`` compensates by buffering, so this
/// affects peak memory rather than the bytes produced.
///
	var patchesInPlace: Bool { get }

/// Append bytes to the destination.
///
/// - Parameters:
///   - bytes: The bytes to append.
///
/// - Throws: ``PackError`` if the bytes could not be written.
///
	mutating func write(_ bytes: UnsafeRawBufferPointer) throws

/// Revise bytes already written.
///
/// - Parameters:
///   - offset: The offset at which to write, which is always within the
///   bytes already written.
///   - bytes: The bytes to write.
///
/// - Throws: ``PackError`` if the destination cannot patch, or if the range
/// lies outside the bytes written so far.
///
	mutating func patch(at offset: Int, with bytes: UnsafeRawBufferPointer) throws
}
