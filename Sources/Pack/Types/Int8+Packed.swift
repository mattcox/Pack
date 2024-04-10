//
//  Int8+Packed.swift
//  Pack
//
//  Created by Matt Cox on 11/02/2022.
//  Copyright © 2024 Matt Cox. All rights reserved.
//

extension Int8: Packed {
	public init(from unpacker: inout Unpacker) throws {
		self = try unpacker.unpack(Int8.self)
	}
	
	public func pack(to packer: inout Packer) throws {
		try packer.pack(self)
	}
}
