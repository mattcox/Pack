//
//  Packer.swift
//  Pack
//
//  Created by Matt Cox on 01/02/2022.
//  Copyright © 2024 Matt Cox. All rights reserved.
//

import Foundation

/// A type that can pack various types into an external representation.
///
public protocol Packer {
/// Get a `Data` object containing the packed data.
///
/// - Throws: ``PackError`` if the packer is writing to an `OutputStream`.
///
	var data: Data { get throws }
	
/// Indicates if the packer is currently packing.
///
/// This is useful in cases where an object acts as both a Packer and an
/// ``Unpacker``, and can only perform either a pack or an unpack at once.
///
	var isPacking: Bool { get }
	
/// The user info for storing local data associated with the current pack.
///
	var userInfo: [PackUserInfoKey: Any] { get set }

/// Initialize a new Packer, writing to a `Data` object owned by the packer.
///
	init()

/// Initialize a new Packer, writing to the provided `OutputStream`.
///
/// - Parameters:
///   - stream: The stream to pack the data into.
///
	init(writingTo stream: OutputStream)
	
/// Pack a `Bool` type value into the packer.
///
/// - Parameters:
///   - value: The `Bool` to pack.
///
/// - Throws: ``PackError`` if the packer is currently not packing values.
///
	mutating func pack(_ value: Bool) throws
	
/// Pack a `Double` type value into the packer.
///
/// - Parameters:
///   - value: The `Double` to pack.
///
/// - Throws: ``PackError`` if the packer is currently not packing values.
///
	mutating func pack(_ value: Double) throws
	
/// Pack a `Float` type value into the packer.
///
/// - Parameters:
///   - value: The `Float` to pack.
///
/// - Throws: ``PackError`` if the packer is currently not packing values.
///
	mutating func pack(_ value: Float) throws
	
/// Pack a `Int` type value into the packer.
///
/// - Parameters:
///   - value: The `Int` to pack.
///
/// - Warning: Care should be taken when packing a `Int` type value, as the
/// size of the type varies depending on the system architecture. If the
/// data is packed on a platform supporting 32 bit architecture, then it
/// will be incompatible with a 64-bit architecture, and vice-versa. For
/// maximum compatibility, use one of the explicitly sized integer types
/// such as `Int32` or `Int64`.
///
/// - Throws: ``PackError`` if the packer is currently not packing values.
///
	mutating func pack(_ value: Int) throws
	
/// Pack an `Int8` type value into the packer.
///
/// - Parameters:
///   - value: The `Int8` to pack.
///
/// - Throws: ``PackError`` if the packer is currently not packing values.
///
	mutating func pack(_ value: Int8) throws

/// Pack an `Int16` type value into the packer.
///
/// - Parameters:
///   - value: The `Int16` to pack.
///
/// - Throws: ``PackError`` if the packer is currently not packing values.
///
	mutating func pack(_ value: Int16) throws

/// Pack an `Int32` type value into the packer.
///
/// - Parameters:
///   - value: The `Int32` to pack.
///
/// - Throws: ``PackError`` if the packer is currently not packing values.
///
	mutating func pack(_ value: Int32) throws
	
/// Pack an `Int64` type value into the packer.
///
/// - Parameters:
///   - value: The `Int64` to pack.
///
/// - Throws: ``PackError`` if the packer is currently not packing values.
///
	mutating func pack(_ value: Int64) throws

/// Pack a `UInt` type value into the packer.
///
/// - Parameters:
///   - value: The `UInt` to pack.
///
/// - Warning: Care should be taken when packing a `UInt` type value, as the
/// size of the type varies depending on the system architecture. If the
/// data is packed on a platform supporting 32 bit architecture, then it
/// will be incompatible with a 64-bit architecture, and vice-versa. For
/// maximum compatibility, use one of the explicitly sized integer types
/// such as `UInt32` or `UInt64`.
///
/// - Throws: ``PackError`` if the packer is currently not packing values.
///
	mutating func pack(_ value: UInt) throws

/// Pack a `UInt8` type value into the packer.
///
/// - Parameters:
///   - value: The `UInt8` to pack.
///
/// - Throws: ``PackError`` if the packer is currently not packing values.
///
	mutating func pack(_ value: UInt8) throws

/// Pack a `UInt16` type value into the packer.
///
/// - Parameters:
///   - value: The `UInt16` to pack.
///
/// - Throws: ``PackError`` if the packer is currently not packing values.
///
	mutating func pack(_ value: UInt16) throws

/// Pack a `UInt32` type value into the packer.
///
/// - Parameters:
///   - value: The `UInt32` to pack.
///
/// - Throws: ``PackError`` if the packer is currently not packing values.
///
	mutating func pack(_ value: UInt32) throws

/// Pack a `UInt64` type value into the packer.
///
/// - Parameters:
///   - value: The `UInt64` to pack.
///
/// - Throws: ``PackError`` if the packer is currently not packing values.
///
	mutating func pack(_ value: UInt64) throws

/// Pack a `String` type value into the packer, with a specified encoding.
///
/// - Parameters:
///   - value: The `String` to pack.
///   - encoding: The string encoding used to encode the characters in the
///   string into memory.
///
/// - Warning: Care should be taken when packing a `String`, to ensure the
/// Encoding of the string will not change. For example, packing a string
/// using `ascii` will store characters in 8 bits, whereas packing the
/// string as `utf32` may result in up to 32 bits per character. To ensure
/// packed strings can always be unpacked, a consistent encoding should be
/// used.
///
/// - Throws: ``PackError`` if the packer is currently not packing values.
///
	mutating func pack(_ value: String, using encoding: String.Encoding) throws
	
/// Pack bytes stored in a `Data` object into the packer.
///
/// - Parameters:
///   - value: The `Data` object containing the bytes to pack.
///
/// - Throws: ``PackError`` if the packer is currently not packing values.
///
	mutating func pack(_ data: Data) throws

/// Pack a type conforming to ``Packable`` into the packer.
///
/// Types can conform to the ``Packable`` protocol, allowing the type
/// itself to describe how its data should be packed.
///
/// - Parameters:
///   - packable: The type conforming to ``Packable`` that should be packed.
///
/// - Throws: ``PackError`` if the packer is currently not packing values.
///
	mutating func pack(_ packable: Packable) throws
}
