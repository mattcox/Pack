//
//  PackerPlaceholder.swift
//  Pack
//
//  Created by Matt Cox on 03/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

/// Establishes the identity of a packer, so that a ``PackerPlaceholder`` can
/// be traced back to the packer that vended it.
///
/// This exists so that value type packers have a stable identity too, which
/// `ObjectIdentifier` alone could not provide.
///
public final class PackerIdentity: Sendable {
	public init() {

	}
}

/// A position in the packed output whose value is not yet known.
///
/// A placeholder is obtained from ``Packer/reserve(byteCount:)`` and consumed
/// by ``Packer/fill(_:with:)``. It carries the identity of the packer that
/// created it, so passing one to a different packer is detected rather than
/// silently corrupting the output.
///
/// Most code should not handle placeholders directly.
/// ``Packer/withLengthPrefix(_:_:)`` reserves and fills one correctly, and is
/// the intended way to frame a span whose length is not known in advance.
///
public struct PackerPlaceholder: Hashable, Sendable {
	internal let owner: ObjectIdentifier
	internal let token: UInt64

/// The offset at which the reserved bytes begin.
///
	public let offset: Int

/// The number of bytes reserved.
///
	public let byteCount: Int

	internal init(owner: PackerIdentity, token: UInt64, offset: Int, byteCount: Int) {
		self.owner = ObjectIdentifier(owner)
		self.token = token
		self.offset = offset
		self.byteCount = byteCount
	}

	internal func isOwned(by identity: PackerIdentity) -> Bool {
		owner == ObjectIdentifier(identity)
	}
}
