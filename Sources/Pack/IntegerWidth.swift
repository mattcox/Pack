//
//  IntegerWidth.swift
//  Pack
//
//  Created by Matt Cox on 03/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

/// The width of an unsigned integer written into a packed representation.
///
/// Pack uses this wherever a size is stored alongside the thing it describes -
/// a length prefix ahead of a span, a count ahead of a collection, or the
/// number of bytes ahead of a string. The width is always named by the caller,
/// because it is part of the layout of the format and cannot be inferred.
///
public enum IntegerWidth: Hashable, Sendable, CaseIterable {
/// An 8-bit unsigned integer, describing up to 255 bytes.
///
	case uint8

/// A 16-bit unsigned integer, describing up to 65,535 bytes.
///
	case uint16

/// A 32-bit unsigned integer, describing up to 4,294,967,295 bytes.
///
	case uint32

/// A 64-bit unsigned integer.
///
/// - Note: This is the appropriate width for framing a binary payload, such
/// as a mesh, an image, or a buffer of samples, any of which can exceed the
/// 4 GB ceiling imposed by ``uint32``.
///
	case uint64

/// The number of bytes occupied by an integer of this width.
///
	public var byteCount: Int {
		switch self {
			case .uint8:
				return 1
			case .uint16:
				return 2
			case .uint32:
				return 4
			case .uint64:
				return 8
		}
	}

/// The largest value representable at this width.
///
	public var maximumValue: UInt64 {
		switch self {
			case .uint8:
				return UInt64(UInt8.max)
			case .uint16:
				return UInt64(UInt16.max)
			case .uint32:
				return UInt64(UInt32.max)
			case .uint64:
				return UInt64.max
		}
	}
}
