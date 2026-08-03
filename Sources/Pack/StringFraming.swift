//
//  StringFraming.swift
//  Pack
//
//  Created by Matt Cox on 03/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

/// Describes how the extent of a packed string is recorded, so that an
/// unpacker knows where the string ends.
///
/// Framing is chosen per call rather than per packer, because a single format
/// routinely mixes all of these - a fixed-size tag, a length-prefixed name,
/// and a null-terminated path can sit in the same structure. A packer supplies
/// a default through its ``PackConfiguration``, and any individual field may
/// override it.
///
public enum StringFraming: Hashable, Sendable {
/// The number of bytes of string data is written immediately before the
/// string, as an unsigned integer of the given width.
///
/// - Parameters:
///   - width: The width of the unsigned integer recording the byte count.
///
	case lengthPrefixed(IntegerWidth)

/// A single zero byte is written after the string data.
///
/// - Warning: Only `ascii` and `utf8` encodings may be null terminated, as
/// other encodings can legitimately contain zero bytes within a character.
/// Packing a string that itself contains a null character also fails, as the
/// result could not be unpacked.
///
	case nullTerminated

/// The string occupies a fixed number of bytes, padded to that width.
///
/// This is the framing used for tags and other fixed-layout identifiers.
/// String data longer than `byteCount` is rejected rather than truncated.
///
/// - Parameters:
///   - byteCount: The exact number of bytes occupied by the field.
///   - padding: The byte used to pad string data shorter than `byteCount`.
///   Trailing padding bytes are stripped when unpacking.
///
	case fixed(byteCount: Int, padding: UInt8 = 0)

/// The string occupies the remainder of the input.
///
/// - Warning: This can only be unpacked as the final value in a source, or
/// as the final value within a limited span. It records nothing, so nothing
/// may follow it.
///
	case untilEnd
}
