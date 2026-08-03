//
//  MeasuringPacker.swift
//  Pack
//
//  Created by Matt Cox on 03/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

import Foundation

/// A ``Packer`` that counts the bytes a value would occupy, and produces none.
///
/// This is useful for sizing a buffer before packing into it:
///
/// ```swift
/// var measure = MeasuringPacker(configuration: .littleEndian)
/// try measure.pack(mesh)
///
/// var destination = DataDestination()
/// destination.reserveCapacity(measure.packedCount)
/// ```
///
/// - Note: This is not how a span records its own length. Measuring a body and
/// then packing it encodes everything twice, which for a large collection is
/// worse than the buffering it would replace. Use
/// ``Packer/withLengthPrefix(_:_:)``, which handles both cases without
/// encoding anything more than once.
///
public struct MeasuringPacker: Packer {
/// The layout rules this packer applies.
///
/// Configuration still matters when measuring, as string encoding and
/// framing both affect how many bytes a value occupies.
///
	public let configuration: PackConfiguration

/// The user info for storing local data associated with the current pack.
///
	public var userInfo: [PackUserInfoKey: any Sendable] = [:]

/// How many bytes would have been packed.
///
	public private(set) var packedCount: Int = 0

	private let identity = PackerIdentity()
	private var nextToken: UInt64 = 0
	private var openTokens: Set<UInt64> = []

/// Initialize a new packer.
///
/// - Parameters:
///   - configuration: The layout rules to apply.
///
	public init(configuration: PackConfiguration) {
		self.configuration = configuration
	}

/// Reserved slots need no special handling when nothing is being written,
/// so this is always `true`.
///
	public var patchesInPlace: Bool {
		true
	}

	public var hasOpenPlaceholders: Bool {
		!openTokens.isEmpty
	}

	public mutating func write(_ bytes: UnsafeRawBufferPointer) throws {
		packedCount += bytes.count
	}

	public mutating func reserve(byteCount: Int) throws -> PackerPlaceholder {
		guard byteCount > 0 else {
			throw PackError(
				.valueOutOfRange,
				offset: packedCount,
				reason: "Cannot reserve \(byteCount) bytes"
			)
		}

		let token = nextToken
		nextToken += 1
		openTokens.insert(token)

		let offset = packedCount
		packedCount += byteCount

		return PackerPlaceholder(owner: identity, token: token, offset: offset, byteCount: byteCount)
	}

	public mutating func fill(_ placeholder: PackerPlaceholder, with bytes: UnsafeRawBufferPointer) throws {
		guard placeholder.isOwned(by: identity) else {
			throw PackError(
				.invalidPlaceholder,
				offset: placeholder.offset,
				reason: "The placeholder was not created by this packer"
			)
		}

		guard bytes.count == placeholder.byteCount else {
			throw PackError(
				.valueOutOfRange,
				offset: placeholder.offset,
				reason: "\(bytes.count) bytes cannot fill a \(placeholder.byteCount) byte placeholder"
			)
		}

		guard openTokens.remove(placeholder.token) != nil else {
			throw PackError(
				.placeholderAlreadyFilled,
				offset: placeholder.offset,
				reason: "The placeholder has already been filled"
			)
		}

		// The bytes themselves are discarded. Their width was already counted
		// when the slot was reserved.
	}
}
