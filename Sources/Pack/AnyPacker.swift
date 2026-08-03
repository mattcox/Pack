//
//  AnyPacker.swift
//  Pack
//
//  Created by Matt Cox on 03/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Foundation

/// A type-erased ``Packer``.
///
/// ``Packable`` takes its packer as a generic parameter, so that packing a
/// value specialises rather than dispatching dynamically for every field. That
/// leaves nowhere to put a packer whose concrete type is not known, because an
/// existential does not conform to the protocol and cannot be passed `inout`.
///
/// AnyPacker is the way out. It is a concrete type that conforms to ``Packer``
/// by forwarding to a packer it holds, so it satisfies the generic parameter
/// while hiding what is underneath.
///
/// ```swift
/// var packer = AnyPacker(BinaryPacker(configuration: .littleEndian))
/// try somethingHoldingAClosure.pack(to: &packer)
/// ```
///
/// Reach for this only where erasure is structurally required - dispatching
/// through a class-bound existential, or invoking a closure captured at a point
/// where no packer yet existed. It costs one dynamic dispatch per call, which
/// is what an existential-based packer would have cost everywhere. Statically
/// typed conformances should take `inout some Packer` and keep the
/// specialisation.
///
/// - Note: The wrapped packer is held by reference internally, so copies of an
/// AnyPacker share one underlying packer. Wrapping a value type packer such as
/// ``MeasuringPacker`` copies it, and the original is not advanced by packing
/// through the wrapper.
///
public struct AnyPacker: Packer {
	private let box: AnyPackerBox

/// Wrap a packer, hiding its concrete type.
///
/// - Parameters:
///   - base: The packer to forward to.
///
	public init(_ base: consuming some Packer) {
		self.box = PackerBox(base)
	}

/// Wrap a packer, hiding its concrete type.
///
/// Wrapping an AnyPacker returns it unchanged, rather than adding a second
/// layer of forwarding.
///
/// - Parameters:
///   - base: The packer to forward to.
///
	public init(_ base: AnyPacker) {
		self.box = base.box
	}

	public var configuration: PackConfiguration {
		box.configuration
	}

	public var userInfo: [PackUserInfoKey: any Sendable] {
		get {
			box.userInfo
		}
		nonmutating set {
			box.userInfo = newValue
		}
	}

	public var packedCount: Int {
		box.packedCount
	}

	public var patchesInPlace: Bool {
		box.patchesInPlace
	}

	public var hasOpenPlaceholders: Bool {
		box.hasOpenPlaceholders
	}

	public func write(_ bytes: UnsafeRawBufferPointer) throws {
		try box.write(bytes)
	}

	public func reserve(byteCount: Int) throws -> PackerPlaceholder {
		try box.reserve(byteCount: byteCount)
	}

	public func fill(_ placeholder: PackerPlaceholder, with bytes: UnsafeRawBufferPointer) throws {
		try box.fill(placeholder, with: bytes)
	}
}

// The wrapped packer is held behind a class so that the requirements can be
// forwarded through a vtable. This is why the protocol's requirements are
// non-generic: a generic requirement could not be called on an existential, and
// erasure would be impossible.
//
private class AnyPackerBox {
	var configuration: PackConfiguration {
		fatalError("abstract")
	}

	var userInfo: [PackUserInfoKey: any Sendable] {
		get {
			fatalError("abstract")
		}
		set {
			fatalError("abstract")
		}
	}

	var packedCount: Int {
		fatalError("abstract")
	}

	var patchesInPlace: Bool {
		fatalError("abstract")
	}

	var hasOpenPlaceholders: Bool {
		fatalError("abstract")
	}

	func write(_ bytes: UnsafeRawBufferPointer) throws {
		fatalError("abstract")
	}

	func reserve(byteCount: Int) throws -> PackerPlaceholder {
		fatalError("abstract")
	}

	func fill(_ placeholder: PackerPlaceholder, with bytes: UnsafeRawBufferPointer) throws {
		fatalError("abstract")
	}
}

private final class PackerBox<Base: Packer>: AnyPackerBox {
	private var base: Base

	init(_ base: Base) {
		self.base = base
	}

	override var configuration: PackConfiguration {
		base.configuration
	}

	override var userInfo: [PackUserInfoKey: any Sendable] {
		get {
			base.userInfo
		}
		set {
			base.userInfo = newValue
		}
	}

	override var packedCount: Int {
		base.packedCount
	}

	override var patchesInPlace: Bool {
		base.patchesInPlace
	}

	override var hasOpenPlaceholders: Bool {
		base.hasOpenPlaceholders
	}

	override func write(_ bytes: UnsafeRawBufferPointer) throws {
		try base.write(bytes)
	}

	override func reserve(byteCount: Int) throws -> PackerPlaceholder {
		try base.reserve(byteCount: byteCount)
	}

	override func fill(_ placeholder: PackerPlaceholder, with bytes: UnsafeRawBufferPointer) throws {
		try base.fill(placeholder, with: bytes)
	}
}
