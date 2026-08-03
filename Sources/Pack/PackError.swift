//
//  PackError.swift
//  Pack
//
//  Created by Matt Cox on 02/02/2022.
//  Copyright © 2024 Matt Cox. All rights reserved.
//

import Foundation

/// An error raised while packing or unpacking.
///
/// The failure kind is carried by ``PackError/Code-swift.struct`` rather than
/// by the case of an enumeration, so that new conditions can be introduced
/// without breaking clients that switch over the existing ones.
///
/// Where the position of the failure is known it is reported in
/// ``PackError/offset``, because locating a fault in a binary file without one
/// is largely guesswork.
///
public struct PackError: Error {
/// Identifies the kind of failure that occurred.
///
	public struct Code: Hashable, Sendable, CustomStringConvertible {
		private let name: String

		private init(_ name: String) {
			self.name = name
		}

		public var description: String {
			name
		}

/// The source ended before the requested value could be read.
///
		public static let endOfInput = Code("endOfInput")

/// A value extended beyond the limit declared for the span containing it.
///
/// This indicates a corrupt or mismatched length, and is reported rather
/// than allowing the read to continue into whatever follows.
///
		public static let overrun = Code("overrun")

/// A value could not be represented in the width chosen for it.
///
/// This covers a length prefix too narrow for the span it describes, a
/// count too large for its prefix width, and string data longer than a
/// fixed-size field.
///
		public static let valueOutOfRange = Code("valueOutOfRange")

/// String data could not be encoded or decoded as requested.
///
		public static let invalidString = Code("invalidString")

/// The requested string encoding cannot be used with the requested
/// framing.
///
		public static let unsupportedEncoding = Code("unsupportedEncoding")

/// The packer or unpacker does not support the requested operation.
///
		public static let unsupportedOperation = Code("unsupportedOperation")

/// A placeholder was used with a packer that did not create it.
///
		public static let invalidPlaceholder = Code("invalidPlaceholder")

/// A placeholder was filled more than once.
///
		public static let placeholderAlreadyFilled = Code("placeholderAlreadyFilled")

/// Packing ended while a reserved slot was still unfilled, leaving the
/// output structurally invalid.
///
		public static let incompleteOutput = Code("incompleteOutput")

/// The destination being packed into failed to accept the data.
///
		public static let destinationFailure = Code("destinationFailure")

/// The source being unpacked from failed to provide the data.
///
		public static let sourceFailure = Code("sourceFailure")
	}

/// The kind of failure that occurred.
///
	public let code: Code

/// The byte offset at which the failure occurred, where known.
///
/// For packing this is the number of bytes written so far; for unpacking,
/// the number consumed.
///
	public let offset: Int?

/// A human readable description of what went wrong, where the code alone is
/// not specific enough.
///
	public let reason: String?

/// The underlying error reported by a destination or source, where there was
/// one.
///
	public let underlying: (any Error)?

/// Initialize a new error.
///
/// - Parameters:
///   - code: The kind of failure that occurred.
///   - offset: The byte offset at which the failure occurred.
///   - reason: A human readable description of what went wrong.
///   - underlying: The underlying error reported by a destination or source.
///
	public init(
		_ code: Code,
		offset: Int? = nil,
		reason: String? = nil,
		underlying: (any Error)? = nil
	) {
		self.code = code
		self.offset = offset
		self.reason = reason
		self.underlying = underlying
	}
}

// `underlying` holds an arbitrary error reported by a destination or source,
// which cannot be statically known to be Sendable. PackError itself adds no
// mutable state, so it is safe to send provided the underlying error is - which
// is the case for the stream errors Pack itself produces.
//
extension PackError: @unchecked Sendable {

}

extension PackError: CustomStringConvertible {
	public var description: String {
		var description = "\(code)"

		if let reason {
			description += ": \(reason)"
		}

		if let offset {
			description += " (at byte \(offset))"
		}

		if let underlying {
			description += " [\(underlying)]"
		}

		return description
	}
}

extension PackError: CustomDebugStringConvertible {
	public var debugDescription: String {
		description
	}
}

extension PackError: LocalizedError {
	public var errorDescription: String? {
		description
	}
}
