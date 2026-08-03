//
//  Unpacker.swift
//  Pack
//
//  Created by Matt Cox on 01/02/2022.
//  Copyright © 2024 Matt Cox. All rights reserved.
//

import Foundation

/// A type that can unpack values from an external representation.
///
/// As with ``Packer``, the requirements here are a small non-generic core -
/// reading bytes, skipping bytes, and bounding a span - and everything a
/// caller uses is built on top in extensions.
///
public protocol Unpacker {
/// The layout rules this unpacker applies.
///
	var configuration: PackConfiguration { get }

/// The user info for storing local data associated with the current unpack.
///
	var userInfo: [PackUserInfoKey: any Sendable] { get set }

/// How many bytes have been consumed so far.
///
/// This makes a span's declared length checkable: a body that consumed more
/// than its header declared indicates a corrupt file.
///
	var unpackedCount: Int { get }

/// How many bytes remain available to read, or `nil` where that cannot be
/// known.
///
/// Within a limited span this reports the remainder of the span rather than
/// the remainder of the source. It is `nil` for a source of indeterminate
/// length, such as a stream, when no limit is in effect.
///
	var remainingCount: Int? { get }

/// Unpack raw bytes from the source, filling the given buffer.
///
/// This is the primitive every other unpacking operation is built from. The
/// bytes are not reordered or interpreted.
///
/// - Parameters:
///   - buffer: The buffer to read into. It is filled completely, or the
///   call throws.
///
/// - Throws: ``PackError`` if the source is exhausted, or if the read would
/// pass the end of the innermost limited span.
///
	mutating func read(into buffer: UnsafeMutableRawBufferPointer) throws

/// Skip forward by the specified number of bytes.
///
/// - Parameters:
///   - byteCount: The number of bytes to skip.
///
/// - Throws: ``PackError`` if the source is exhausted, or if the skip would
/// pass the end of the innermost limited span.
///
	mutating func skip(_ byteCount: Int) throws

/// Bound subsequent reads to a span of the given length.
///
/// Reads are checked against the limit as they happen, so a corrupt length
/// cannot be used to read on into whatever follows the span.
///
/// Prefer ``withLimit(byteCount:_:)`` over calling this directly.
///
/// - Parameters:
///   - byteCount: The length of the span, measured from the current
///   position.
///
/// - Throws: ``PackError`` if the span would extend beyond an enclosing
/// limit, or beyond the end of a source whose length is known.
///
	mutating func pushLimit(byteCount: Int) throws

/// Remove the innermost limit.
///
/// - Parameters:
///   - skippingRemainder: Whether to advance to the end of the span before
///   removing the limit. This is what allows a reader to accept a span
///   containing fields it does not recognise.
///
/// - Throws: ``PackError`` if there is no limit in effect, or if the
/// remainder could not be skipped.
///
	mutating func popLimit(skippingRemainder: Bool) throws
}
