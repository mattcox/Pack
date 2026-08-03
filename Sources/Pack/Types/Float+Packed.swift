//
//  Float+Packed.swift
//  Pack
//
//  Created by Matt Cox on 11/02/2022.
//  Copyright © 2024 Matt Cox. All rights reserved.
//

extension Float: Packed {
	public init(from unpacker: inout some Unpacker) throws {
		self = try unpacker.unpack(Float.self)
	}

	public func pack(to packer: inout some Packer) throws {
		try packer.pack(self)
	}
}
