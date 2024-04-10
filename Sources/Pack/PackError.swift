//
//  PackError.swift
//  Pack
//
//  Created by Matt Cox on 02/02/2022.
//  Copyright © 2024 Matt Cox. All rights reserved.
//

/// Errors used by Pack.
///
public enum PackError: Swift.Error {
/// An Error indicating a general failure.
///
/// - Parameters:
///   - reason: An optional string describing the reason for the failure.
///
	case failure(reason: String? = nil)
	
/// Indicates that a packing operation of some form has been attempted, but
/// data is currently not being packed.
///
	case notPacking

/// Indicates that a unpacking operation of some form has been attempted,
/// but data is currently not being unpacked.
///
	case notUnpacking
	
/// Indicates that the destination for packing data is invalid.
///
/// - Parameters:
///   - reason: An optional string describing the reason for the failure.
///
	case invalidPackingDestination
	
/// Indicates that the data source for unpacking is invalid.
///
/// - Parameters:
///   - reason: An optional string describing the reason for the failure.
///
	case invalidUnpackingSource
	
/// Indicates that either there is not enough room in the destination object
/// to pack the provided data, or there is not enough data in the source
/// object to read.
///
	case shortBuffer
	
/// Indicates that the specified string encoding is unsupported.
///
	case unsupportedEncoding
	
/// Indicates a general "unknown" error.
///
/// This error is mostly a catch-all and should be avoided where possible.
///
	case unknown
}

// Conform Error to CustomDebugStringConvertible.
//
extension PackError: CustomDebugStringConvertible {
	public var debugDescription: String {
		switch self {
			case .failure(let reason):
				if let reason = reason {
					return "Failed: \(reason)"
				}
				else {
					return "Failed"
				}
				
			case .notPacking:
				return "Not Packing"
				
			case .notUnpacking:
				return "Not Unpacking"
				
			case .invalidPackingDestination:
				return "Invalid Packing Destination"
				
			case .invalidUnpackingSource:
				return "Invalid Unpacking Source"
				
			case .shortBuffer:
				return "Short Buffer"
				
			case .unsupportedEncoding:
				return "Unsupported Encoding"
				
			case .unknown:
				return "Unknown"
		}
	}
}
