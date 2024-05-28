//
//  Unpacker.swift
//  Pack
//
//  Created by Matt Cox on 01/02/2022.
//  Copyright © 2024 Matt Cox. All rights reserved.
//

import Foundation

/// A type that can unpack various types from an external representation.
///
public protocol Unpacker {
/// Indicates if the unpacker is currently unpacking.
///
/// This is useful in cases where an object acts as both an Unpacker and a
/// ``Packer``, and can only perform either a pack or an unpack at once.
///
	var isUnpacking: Bool { get }
	
/// The user info for storing local data associated with the current unpack.
///
	var userInfo: [PackUserInfoKey: Any] { get set }

/// Initialize a new Packer, reading data from the provided `Data` object.
///
/// - Parameters:
///   - data: The `Data` object to unpack data from.
///
	init(from data: Data)

/// Initialize a new Packer, reading from the provided `InputStream`.
///
/// - Parameters:
///   - stream: The stream to unpack data from.
///
	init(readingFrom stream: InputStream)
	
/// Offset the current read index by the specified amount in bytes.
///
/// This can be useful for skipping over certain blocks of data.
///
/// - Parameters:
///   - count: The amount to offset the read index in bytes. For example, a
///   value of 1 would offset 8 bits forward.
///
/// - Throws: ``PackError`` if the unpacker is currently not unpacking
/// values, or if the end of the input source is reached.
///
	mutating func offset(by count: UInt) throws

/// Unpack a `Bool` type value from the data source.
///
/// - Parameters:
///   - type: The type of object to unpack.
///
/// - Returns: A `Bool` value unpacked from the data source.
///
/// - Throws: ``PackError`` if the unpacker is currently not unpacking
/// values, or if the end of the input source is reached.
///
	mutating func unpack(_ type: Bool.Type) throws -> Bool

/// Unpack a `Double` type value from the data source.
///
/// - Parameters:
///   - type: The type of object to unpack.
///
/// - Returns: A `Double` value unpacked from the data source.
///
/// - Throws: ``PackError`` if the unpacker is currently not unpacking
/// values, or if the end of the input source is reached.
///
	mutating func unpack(_ type: Double.Type) throws -> Double

/// Unpack a `Float` type value from the data source.
///
/// - Parameters:
///   - type: The type of object to unpack.
///
/// - Returns: A `Float` value unpacked from the data source.
///
/// - Throws: ``PackError`` if the unpacker is currently not unpacking
/// values, or if the end of the input source is reached.
///
	mutating func unpack(_ type: Float.Type) throws -> Float

/// Unpack a `Int` type value from the data source.
///
/// - Parameters:
///   - type: The type of object to unpack.
///
/// - Warning: Care should be taken when unpacking an `Int` type value, as
/// the size of the type varies depending on the system architecture. If the
/// data is packed on a platform supporting 32 bit architecture, then it
/// will be incompatible with a 64-bit architecture, and vice-versa. For
/// maximum compatibility, use one of the explicitly sized integer types
/// such as `Int32` or `Int64`.
///
/// - Returns: A `Int` value unpacked from the data source.
///
/// - Throws: ``PackError`` if the unpacker is currently not unpacking
/// values, or if the end of the input source is reached.
///
	mutating func unpack(_ type: Int.Type) throws -> Int

/// Unpack a `Int8` type value from the data source.
///
/// - Parameters:
///   - type: The type of object to unpack.
///
/// - Returns: A `Int8` value unpacked from the data source.
///
/// - Throws: ``PackError`` if the unpacker is currently not unpacking
/// values, or if the end of the input source is reached.
///
	mutating func unpack(_ type: Int8.Type) throws -> Int8

/// Unpack a `Int16` type value from the data source.
///
/// - Parameters:
///   - type: The type of object to unpack.
///
/// - Returns: A `Int16` value unpacked from the data source.
///
/// - Throws: ``PackError`` if the unpacker is currently not unpacking
/// values, or if the end of the input source is reached.
///
	mutating func unpack(_ type: Int16.Type) throws -> Int16

/// Unpack a `Int32` type value from the data source.
///
/// - Parameters:
///   - type: The type of object to unpack.
///
/// - Returns: A `Int32` value unpacked from the data source.
///
/// - Throws: ``PackError`` if the unpacker is currently not unpacking
/// values, or if the end of the input source is reached.
///
	mutating func unpack(_ type: Int32.Type) throws -> Int32

/// Unpack a `Int64` type value from the data source.
///
/// - Parameters:
///   - type: The type of object to unpack.
///
/// - Returns: A `Int64` value unpacked from the data source.
///
/// - Throws: ``PackError`` if the unpacker is currently not unpacking
/// values, or if the end of the input source is reached.
///
	mutating func unpack(_ type: Int64.Type) throws -> Int64

/// Unpack a `UInt` type value from the data source.
///
/// - Warning: Care should be taken when unpacking an `UInt` type value, as
/// the size of the type varies depending on the system architecture. If the
/// data is packed on a platform supporting 32 bit architecture, then it
/// will be incompatible with a 64-bit architecture, and vice-versa. For
/// maximum compatibility, use one of the explicitly sized integer types
/// such as `UInt32` or `UInt64`.
///
/// - Parameters:
///   - type: The type of object to unpack.
///
/// - Returns: A `UInt` value unpacked from the data source.
///
/// - Throws: ``PackError`` if the unpacker is currently not unpacking
/// values, or if the end of the input source is reached.
///
	mutating func unpack(_ type: UInt.Type) throws -> UInt

/// Unpack a `UInt8` type value from the data source.c
///
/// - Parameters:
///   - type: The type of object to unpack.
///
/// - Returns: A `UInt8` value unpacked from the data source.
///
/// - Throws: ``PackError`` if the unpacker is currently not unpacking
/// values, or if the end of the input source is reached.
///
	mutating func unpack(_ type: UInt8.Type) throws -> UInt8

/// Unpack a `UInt16` type value from the data source.
///
/// - Parameters:
///   - type: The type of object to unpack.
///
/// - Returns: A `UInt16` value unpacked from the data source.
///
/// - Throws: ``PackError`` if the unpacker is currently not unpacking
/// values, or if the end of the input source is reached.
///
	mutating func unpack(_ type: UInt16.Type) throws -> UInt16

/// Unpack a `UInt32` type value from the data source.
///
/// - Parameters:
///   - type: The type of object to unpack.
///
/// - Returns: A `UInt32` value unpacked from the data source.
///
/// - Throws: ``PackError`` if the unpacker is currently not unpacking
/// values, or if the end of the input source is reached.
///
	mutating func unpack(_ type: UInt32.Type) throws -> UInt32

/// Unpack a `UInt64` type value from the data source.
///
/// - Parameters:
///   - type: The type of object to unpack.
///
/// - Returns: A `UInt64` value unpacked from the data source.
///
/// - Throws: ``PackError`` if the unpacker is currently not unpacking
/// values, or if the end of the input source is reached.
///
	mutating func unpack(_ type: UInt64.Type) throws -> UInt64

/// Unpack a `String` type value from the data source, packed with the
/// specified encoding.
///
/// - Warning: Care should be taken when unpacking a `String`, to ensure the
/// Encoding of the string is the same as when it was packed. For example,
/// packing a string using `ascii` will store characters in 8 bits, whereas
/// packing the string as `utf32` may result in up to 32 bits per character.
/// To ensure packed strings can always be unpacked, a consistent encoding
/// should be used.
///
/// - Parameters:
///   - type: The type of object to unpack.
///   - encoding: The string encoding that the string was encoded with when
///   packing.
///
/// - Throws: ``PackError`` if the unpacker is currently not unpacking
/// values, or if the end of the input source is reached.
///
	mutating func unpack(_ type: String.Type, using encoding: String.Encoding) throws -> String

/// Unpack bytes from the data source, without interpreting the data as a
/// specific type. The number of bytes to read can be specified.
///
/// - Parameters:
///   - type: The type of object to unpack.
///   - size: The number of bytes to read from the data source.
///
/// - Throws: ``PackError`` if the unpacker is currently not unpacking
/// values, or if the end of the input source is reached.
///
	mutating func unpack(_ type: Data.Type, size: Int) throws -> Data

/// Unpack a type conforming to ``Unpackable`` from the data source.
///
/// Types can conform to the ``Unpackable`` protocol, allowing the type
/// itself to describe how its data should be unpacked.
///
/// - Parameters:
///   - type: The type of object to unpack.
///
/// - Returns: The ``Unpackable`` type unpacked from the data source.
///
/// - Throws: ``PackError`` if the unpacker is currently not unpacking
/// values, or if the end of the input source is reached.
///
	mutating func unpack<T: Unpackable>(_ type: T.Type) throws -> T
}
