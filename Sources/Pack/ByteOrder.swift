//
//  ByteOrder.swift
//  Pack
//
//  Created by Matt Cox on 07/02/2022.
//  Copyright © 2024 Matt Cox. All rights reserved.
//

/// Describes the order or sequence of bytes of data in memory.
///
/// A big-endian system stores the most significant byte at the smallest memory
/// address, and the least significant byte at the largest. A little-endian
/// system stores the least-significant byte at the smallest address.
///
/// The vast majority of modern computing platforms use little-endian, however
/// some file formats continue to use big-endian encoding.
///
public enum ByteOrder: Hashable, Sendable {
/// A little-endian byte order.
///
/// Little-endian stores least significant byte at the smallest address, and
/// the most significant byte at the largest address.
///
/// - Note: This byte order is most common on modern computing platforms.
///
	case littleEndian

/// A big-endian byte order.
///
/// Big-endian stores most significant byte at the smallest address, and the
/// least significant byte at the largest address.
///
	case bigEndian

/// The byte order used by the system this module has been compiled for.
///
/// - Warning: This is provided for inspection, not for configuring a packer.
/// Packing with the host byte order produces a file whose layout depends on
/// the machine that wrote it. Name an endianness explicitly instead.
///
	public static let system: ByteOrder = {
#if _endian(big)
		return .bigEndian
#else
		return .littleEndian
#endif
	}()
}
