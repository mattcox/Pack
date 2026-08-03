//
//  Unpackable.swift
//  Pack
//
//  Created by Matt Cox on 01/02/2022.
//  Copyright © 2024 Matt Cox. All rights reserved.
//

/// A type that can unpack itself from an external representation.
///
/// As with ``Packable``, the unpacker is a generic parameter so that unpacking
/// specialises. Conformances use `some`:
///
/// ```swift
/// extension Color: Unpackable {
///     init(from unpacker: inout some Unpacker) throws {
///         self.name = try unpacker.unpack(String.self, framing: .lengthPrefixed(.uint32))
///         self.red = try unpacker.unpack(Double.self)
///         self.green = try unpacker.unpack(Double.self)
///         self.blue = try unpacker.unpack(Double.self)
///         self.alpha = try unpacker.unpack(Double.self)
///     }
/// }
/// ```
///
public protocol Unpackable {
/// Creates a new instance of this object by unpacking data using the
/// provided unpacker.
///
/// - Parameters:
///   - unpacker: The unpacker to unpack the data from.
///
/// - Throws: ``PackError`` if unpacking the data fails, or if the data
/// source is corrupted or otherwise invalid.
///
	init<U: Unpacker>(from unpacker: inout U) throws
}
