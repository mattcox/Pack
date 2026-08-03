//
//  Packable.swift
//  Pack
//
//  Created by Matt Cox on 01/02/2022.
//  Copyright © 2024 Matt Cox. All rights reserved.
//

/// A type that can pack itself into an external representation.
///
/// The packer is a generic parameter rather than an existential, so that
/// packing a value specialises to direct calls on the concrete packer instead
/// of dispatching dynamically for every field.
///
/// Conformances read the same as they would with an existential, using `some`:
///
/// ```swift
/// extension Color: Packable {
///     func pack(to packer: inout some Packer) throws {
///         try packer.pack(name, framing: .lengthPrefixed(.uint32))
///         try packer.pack(red)
///         try packer.pack(green)
///         try packer.pack(blue)
///         try packer.pack(alpha)
///     }
/// }
/// ```
///
/// Where the packer's concrete type genuinely cannot be known - dispatching
/// through a class-bound existential, or invoking a closure captured before any
/// packer existed - wrap it in ``AnyPacker``, which is a concrete type and so
/// satisfies the generic parameter.
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
	func pack<P: Packer>(to packer: inout P) throws
}
