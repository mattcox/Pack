//
//  Unpackable.swift
//  Pack
//
//  Created by Matt Cox on 01/02/2022.
//  Copyright © 2024 Matt Cox. All rights reserved.
//

/// A type that can unpack itself from an external representation.
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
	init(from unpacker: inout Unpacker) throws
}
