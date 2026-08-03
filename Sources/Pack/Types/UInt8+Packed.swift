//
//  UInt8+Packed.swift
//  Pack
//
//  Created by Matt Cox on 11/02/2022.
//  Copyright © 2024 Matt Cox. All rights reserved.
//

extension UInt8: Packed {
	public init(from unpacker: inout some Unpacker) throws {
		self = try unpacker.unpack(UInt8.self)
	}

	public func pack(to packer: inout some Packer) throws {
		try packer.pack(self)
	}
}
