//
//  Packed.swift
//  Pack
//
//  Created by Matt Cox on 01/02/2022.
//  Copyright © 2024 Matt Cox. All rights reserved.
//

/// A type that can pack and unpack itself into and out of an external
/// representation.
///
/// Packed is a type alias for the ``Packable`` and ``Unpackable`` protocols.
/// When you use Packed as a type or a generic constraint, it matches any type
/// that conforms to both protocols.
///
public typealias Packed = Packable & Unpackable
