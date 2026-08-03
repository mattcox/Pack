//
//  PortableInteger.swift
//  Pack
//
//  Created by Matt Cox on 03/08/2026.
//  Copyright © 2026 Matt Cox. All rights reserved.
//

/// An integer whose width does not depend on the architecture it is compiled
/// for, and which is therefore safe to write into a file.
///
/// Pack's integer APIs are constrained to this rather than to
/// `FixedWidthInteger`, so that `Int` and `UInt` - which are 32 bits on some
/// platforms and 64 on others - cannot be packed by accident. A file written
/// with `Int` is readable only on a machine of matching width, and would not
/// fail on the machine it was tested on.
///
/// Widen explicitly at the call site instead:
///
/// ```swift
/// try packer.pack(Int64(someInt))
/// ```
///
/// A custom integer type of fixed width may conform, and can then be packed
/// like any other.
///
/// - Note: `Int` and `UInt` deliberately do not conform, and never should.
///
public protocol PortableInteger: FixedWidthInteger {

}

extension Int8: PortableInteger {

}

extension Int16: PortableInteger {

}

extension Int32: PortableInteger {

}

extension Int64: PortableInteger {

}

extension UInt8: PortableInteger {

}

extension UInt16: PortableInteger {

}

extension UInt32: PortableInteger {

}

extension UInt64: PortableInteger {

}
