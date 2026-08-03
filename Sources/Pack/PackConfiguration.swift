//
//  PackConfiguration.swift
//  Pack
//
//  Created by Matt Cox on 03/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Foundation

/// The layout rules a packer or unpacker applies.
///
/// Everything that affects the bytes on disk is gathered here and pinned at
/// construction. There is no process-wide default and no host-dependent
/// fallback, because a format cannot be built on either - the same source must
/// produce the same bytes on every machine that runs it.
///
/// Byte order has no default value. You name an endianness, or you do not get
/// a packer.
///
public struct PackConfiguration: Hashable, Sendable {
/// The byte order used for multi-byte scalar values.
///
/// String data is never reordered. Where a specific byte order is required
/// for text, use the corresponding encoding, such as `utf16BigEndian`.
///
	public var byteOrder: ByteOrder

/// The string encoding used when a call does not name one.
///
	public var defaultStringEncoding: String.Encoding

/// The string framing used when a call does not name one.
///
	public var defaultStringFraming: StringFraming

/// Initialize a new configuration.
///
/// - Parameters:
///   - byteOrder: The byte order used for multi-byte scalar values.
///   - defaultStringEncoding: The string encoding used when a call does not
///   name one.
///   - defaultStringFraming: The string framing used when a call does not
///   name one.
///
	public init(
		byteOrder: ByteOrder,
		defaultStringEncoding: String.Encoding = .utf8,
		defaultStringFraming: StringFraming = .lengthPrefixed(.uint32)
	) {
		self.byteOrder = byteOrder
		self.defaultStringEncoding = defaultStringEncoding
		self.defaultStringFraming = defaultStringFraming
	}

/// A little-endian configuration, packing strings as utf8 prefixed with a
/// 32-bit byte count.
///
	public static let littleEndian = PackConfiguration(byteOrder: .littleEndian)

/// A big-endian configuration, packing strings as utf8 prefixed with a
/// 32-bit byte count.
///
	public static let bigEndian = PackConfiguration(byteOrder: .bigEndian)
}
