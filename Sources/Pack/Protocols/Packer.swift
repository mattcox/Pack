//
//  Packer.swift
//  Pack
//
//  Created by Matt Cox on 01/02/2022.
//  Copyright © 2024 Matt Cox. All rights reserved.
//

import Foundation

/// A type that can pack values into an external representation.
///
/// The requirements below are the whole of what a packer must implement: how
/// to accept bytes, how to reserve and later fill a fixed-width slot, and what
/// layout rules it applies. Everything a caller actually uses - packing
/// integers, strings, collections, and ``Packable`` types, and framing spans
/// with ``withLengthPrefix(_:_:)`` - is built on top of these in extensions,
/// defined once and shared by every packer.
///
/// That split is deliberate. It keeps conformance small, it means the encoding
/// rules exist in exactly one place rather than once per packer, and it keeps
/// the required surface non-generic so ``AnyPacker`` can forward it.
///
/// Note that conformance does not require any particular initializer. A packer
/// is free to be constructed however suits it, which is what allows packers
/// that have no byte destination at all, such as ``MeasuringPacker``.
///
public protocol Packer {
/// The layout rules this packer applies.
///
	var configuration: PackConfiguration { get }

/// The user info for storing local data associated with the current pack.
///
	var userInfo: [PackUserInfoKey: any Sendable] { get set }

/// How many bytes have been packed so far.
///
/// This is what makes a length computable - the difference between the
/// value before and after packing a body.
///
/// The count is logical. It advances past reserved slots and past the body
/// of a span that is still being buffered, so it means the same thing
/// whether or not the underlying destination can be patched.
///
	var packedCount: Int { get }

/// Whether reserved slots are patched directly into output already written.
///
/// When `false`, the packer buffers the body of a reserved span in memory
/// until the slot is filled, because the output it would need to patch has
/// already been handed off - to a stream, typically.
///
/// The packed bytes are identical either way, and so is the behaviour -
/// including the order in which reserved slots may be filled. This reports a
/// difference in peak memory only, and is not a capability a caller needs to
/// branch on.
///
	var patchesInPlace: Bool { get }

/// Whether any reserved slot has yet to be filled.
///
/// Packed output is complete only when this is `false`. Prefer calling
/// ``finish()``, which reports an incomplete state as an error rather than
/// leaving it to be noticed.
///
	var hasOpenPlaceholders: Bool { get }

/// Pack raw bytes into the packer, exactly as given.
///
/// This is the primitive every other packing operation is built from. The
/// bytes are not reordered, framed, or interpreted.
///
/// - Parameters:
///   - bytes: The bytes to pack.
///
/// - Throws: ``PackError`` if the destination could not accept the bytes.
///
	mutating func write(_ bytes: UnsafeRawBufferPointer) throws

/// Reserve a fixed number of bytes to be filled in later.
///
/// Use this where a value must appear before the thing that determines it -
/// a length ahead of the body it measures, most commonly. Reserved bytes
/// count towards ``packedCount`` immediately.
///
/// Prefer ``withLengthPrefix(_:_:)``, which reserves and fills a length
/// correctly, over calling this directly.
///
/// - Parameters:
///   - byteCount: The number of bytes to reserve.
///
/// - Returns: A placeholder identifying the reserved bytes.
///
/// - Throws: ``PackError`` if the bytes could not be reserved.
///
	mutating func reserve(byteCount: Int) throws -> PackerPlaceholder

/// Fill bytes previously reserved.
///
/// - Parameters:
///   - placeholder: The placeholder identifying the reserved bytes.
///   - bytes: The bytes to write into the reserved slot. The count must
///   match the reserved width exactly.
///
/// - Throws: ``PackError`` if the placeholder was not vended by this packer,
/// has already been filled, is being filled out of order, or if the byte
/// count does not match the width reserved.
///
	mutating func fill(_ placeholder: PackerPlaceholder, with bytes: UnsafeRawBufferPointer) throws
}
