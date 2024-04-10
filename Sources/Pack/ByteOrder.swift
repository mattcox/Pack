//
//  ByteOrder.swift
//  Pack
//
//  Created by Matt Cox on 07/02/2022.
//  Copyright © 2024 Matt Cox. All rights reserved.
//

import CoreFoundation
import Foundation

/// Describes the order or sequence of bytes of data in memory.
///
/// A big-endian system stores the most significant byte at the smallest memory
/// address, and the least significant byte at the largest. A little-endian
/// system stores the least-significant byte at the smallest address.
///
/// The vast majority of modern computing platforms use little-endian, however
/// some file formats continue to use big-endian encoding.
///
public enum ByteOrder {
/// An unknown byte order.
///
/// This byte order is unsupported, and is used for handling errors only.
///
	case unknown

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
	public static var system: ByteOrder = ByteOrder(from: CFByteOrderGetCurrent())
	
/// Returns the byte order as a `CFByteOrder` Core Foundation type.
///
	public var byteOrder: CFByteOrder {
		switch self {
			case .unknown:
				return CFByteOrder(CFByteOrderUnknown.rawValue)
			case .littleEndian:
				return CFByteOrder(CFByteOrderLittleEndian.rawValue)
			case .bigEndian:
				return CFByteOrder(CFByteOrderBigEndian.rawValue)
		}
	}
	
/// Initialise a new `ByteOrder` object from a `CFByteOrder` Core Foundation
/// type.
///
/// - Parameters:
///   - byteOrder: The `CFByteOrder` describing the endianness of the new
///   `ByteOrder`.
///
	public init(from byteOrder: CFByteOrder) {
		if byteOrder == CFByteOrderUnknown.rawValue {
			assertionFailure("Unknown CFByteOrder")
			self = .unknown
		}
		else if byteOrder == CFByteOrderLittleEndian.rawValue {
			self = .littleEndian
		}
		else if byteOrder == CFByteOrderBigEndian.rawValue {
			self = .bigEndian
		}
		else {
			// This is here incase CFByteOrder is extended in future to
			// support other byte orders.
			//
			preconditionFailure("Unsupported CFByteOrder")
		}
	}

/// Swap the byte order of some data from one byte order to another.
///
/// - Parameters:
///   - data: The `Data` object whose bytes should be swapped.
///   - byteOrder: The `ByteOrder` that the bytes will be swapped into.
///
/// - Returns: A boolean indicating if the byte order of the memory was
/// modified.
///
	@discardableResult
	public func swap(_ data: inout Data, to byteOrder: ByteOrder) -> Bool {
		ByteOrder.swap(&data, from: self, to: byteOrder)
	}
	
/// Swap the byte order of some data from one byte order to another.
///
/// - Parameters:
///   - data: The `Data` object whose bytes should be swapped.
///   - fromByteOrder: The `ByteOrder` that the bytes are currently in.
///   - toByteOrder: The `ByteOrder` that the bytes will be swapped into.
///
/// - Returns: A boolean indicating if the byte order of the memory was
/// modified.
///
	@discardableResult
	static public func swap(_ data: inout Data, from fromByteOrder: ByteOrder, to toByteOrder: ByteOrder) -> Bool {
		if fromByteOrder == toByteOrder || fromByteOrder == .unknown || toByteOrder == .unknown {
			return false
		}
		
		data.reverse()
		return true
	}
}
