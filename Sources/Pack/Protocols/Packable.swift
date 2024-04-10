//
//  Packable.swift
//  Pack
//
//  Created by Matt Cox on 01/02/2022.
//  Copyright © 2024 Matt Cox. All rights reserved.
//

/// A type that can pack itself into an external representation.
///
public protocol Packable {
/// Packs this value using the provided packer.
///
/// - Parameters:
///   - packer: The packer to pack data into.
///
/// - Throws: ``PackError`` if any values are invalid for the given packer
/// format.
///
	func pack(to packer: inout Packer) throws
}
