//
//  AnyUnpacker.swift
//  Pack
//
//  Created by Matt Cox on 03/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Foundation

/// A type-erased ``Unpacker``.
///
/// The counterpart to ``AnyPacker``, for the same reasons. Reach for it only
/// where the unpacker's concrete type genuinely cannot be known; statically
/// typed conformances should take `inout some Unpacker`.
///
/// - Note: The wrapped unpacker is held by reference internally, so copies of
/// an AnyUnpacker share one underlying unpacker.
///
public struct AnyUnpacker: Unpacker {
	private let box: AnyUnpackerBox

/// Wrap an unpacker, hiding its concrete type.
///
/// - Parameters:
///   - base: The unpacker to forward to.
///
	public init(_ base: consuming some Unpacker) {
		self.box = UnpackerBox(base)
	}

/// Wrap an unpacker, hiding its concrete type.
///
/// Wrapping an AnyUnpacker returns it unchanged, rather than adding a second
/// layer of forwarding.
///
/// - Parameters:
///   - base: The unpacker to forward to.
///
	public init(_ base: AnyUnpacker) {
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

	public var unpackedCount: Int {
		box.unpackedCount
	}

	public var remainingCount: Int? {
		box.remainingCount
	}

	public func read(into buffer: UnsafeMutableRawBufferPointer) throws {
		try box.read(into: buffer)
	}

	public func skip(_ byteCount: Int) throws {
		try box.skip(byteCount)
	}

	public func pushLimit(byteCount: Int) throws {
		try box.pushLimit(byteCount: byteCount)
	}

	public func popLimit(skippingRemainder: Bool) throws {
		try box.popLimit(skippingRemainder: skippingRemainder)
	}
}

private class AnyUnpackerBox {
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

	var unpackedCount: Int {
		fatalError("abstract")
	}

	var remainingCount: Int? {
		fatalError("abstract")
	}

	func read(into buffer: UnsafeMutableRawBufferPointer) throws {
		fatalError("abstract")
	}

	func skip(_ byteCount: Int) throws {
		fatalError("abstract")
	}

	func pushLimit(byteCount: Int) throws {
		fatalError("abstract")
	}

	func popLimit(skippingRemainder: Bool) throws {
		fatalError("abstract")
	}
}

private final class UnpackerBox<Base: Unpacker>: AnyUnpackerBox {
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

	override var unpackedCount: Int {
		base.unpackedCount
	}

	override var remainingCount: Int? {
		base.remainingCount
	}

	override func read(into buffer: UnsafeMutableRawBufferPointer) throws {
		try base.read(into: buffer)
	}

	override func skip(_ byteCount: Int) throws {
		try base.skip(byteCount)
	}

	override func pushLimit(byteCount: Int) throws {
		try base.pushLimit(byteCount: byteCount)
	}

	override func popLimit(skippingRemainder: Bool) throws {
		try base.popLimit(skippingRemainder: skippingRemainder)
	}
}
