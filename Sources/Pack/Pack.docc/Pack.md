# ``Pack``

Serialize and deserialize values into an external binary representation.

## Overview

Pack encodes and decodes values as raw binary, for storing data efficiently on
disk or sending it across a network. It is similar in purpose to the built-in
`Codable` protocols, but unlike `Codable` it is not key/value based: the layout
of the bytes is described by the code that writes them, and is the format.

That difference is the point. Every decision that affects the bytes on disk is
made explicitly at the call site - the byte order, the width of every integer,
the encoding and framing of every string - and none of it is inherited from the
machine the code happens to be running on.

![A structure being packed into binary, and being unpacked from binary.](pack.png)

```swift
var packer = BinaryPacker(configuration: .littleEndian)
try packer.pack(Int64(12345))
try packer.pack(6789.0)
try packer.pack("Hello, world!")

let data = packer.data
```

Any type can describe how it is packed by conforming to ``Packable`` and
``Unpackable``:

```swift
extension Color: Packed {
    func pack(to packer: inout some Packer) throws {
        try packer.pack(name, using: .utf16, framing: .lengthPrefixed(.uint32))
        try packer.pack(red)
        try packer.pack(green)
        try packer.pack(blue)
        try packer.pack(alpha)
    }

    init(from unpacker: inout some Unpacker) throws {
        self.name = try unpacker.unpack(String.self, using: .utf16, framing: .lengthPrefixed(.uint32))
        self.red = try unpacker.unpack(Double.self)
        self.green = try unpacker.unpack(Double.self)
        self.blue = try unpacker.unpack(Double.self)
        self.alpha = try unpacker.unpack(Double.self)
    }
}
```

### Framing

A format usually needs to record how long something is before it has been
written. ``Packer/withLengthPrefix(_:_:)`` reserves the length, packs the body,
and fills the length in afterwards:

```swift
try packer.pack(tag, using: .ascii, framing: .fixed(byteCount: 4))
try packer.withLengthPrefix(.uint64) { packer in
    try packer.pack(mesh)
}
```

This produces the same bytes whatever the destination. A packer writing to
memory patches the length in place; a packer writing to a stream, which cannot
revise what it has already handed over, buffers the body until the length is
known.

Reading back, ``Unpacker/withLimit(byteCount:_:)`` bounds a span so that a
length which does not match its contents is reported rather than allowed to run
on into whatever follows. It also skips anything within the span that was not
read, which is what lets an older reader accept a span a newer writer has added
fields to:

```swift
let length = try unpacker.unpack(UInt64.self)
try unpacker.withLimit(byteCount: Int(length)) { unpacker in
    // read the fields this version knows about
}
```

### Architecture dependent integers

`Int` and `UInt` change width between platforms, so a file written with them is
readable only on a machine of matching width - and would not fail on the machine
it was tested on. Pack's integer APIs are constrained to ``PortableInteger``,
which `Int` and `UInt` deliberately do not conform to, so using one is a compile
error rather than a corrupt file discovered later.

```swift
try packer.pack(Int64(value))
```

## Topics

### Packing and unpacking
- ``BinaryPacker``
- ``BinaryUnpacker``
- ``PackConfiguration``

### Describing a layout
- ``Packed``
- ``Packable``
- ``Unpackable``
- ``PortableInteger``
- ``IntegerWidth``
- ``StringFraming``
- ``ByteOrder``

### Framing
- ``PackerPlaceholder``

### Protocols
- ``Packer``
- ``Unpacker``
- ``PackDestination``
- ``UnpackSource``

### Destinations and sources
- ``DataDestination``
- ``OutputStreamDestination``
- ``DataSource``
- ``InputStreamSource``

### Other packers
- ``MeasuringPacker``
- ``AnyPacker``
- ``AnyUnpacker``

### Supporting types
- ``PackError``
- ``PackUserInfoKey``
