//
//  PackUserInfoKey.swift
//  Pack
//
//  Created by Matt Cox on 28/05/2024.
//  Copyright © 2024 Matt Cox. All rights reserved.
//

import Foundation

/// A user-defined key for providing context during packing and unpacking.
///
public struct PackUserInfoKey: RawRepresentable {
	public let rawValue: String
	
	public init(rawValue: String) {
		self.rawValue = rawValue
	}
}

extension PackUserInfoKey: CustomStringConvertible {
	public var description: String {
		rawValue
	}
}

extension PackUserInfoKey: Equatable {
	
}

extension PackUserInfoKey: Hashable {
	
}

extension PackUserInfoKey: Sendable {
	
}
