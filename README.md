# Pack

<p align="center">
    <img src="https://img.shields.io/badge/Swift-orange.svg" alt="Swift" />
    <a href="https://swift.org/package-manager">
        <img src="https://img.shields.io/badge/swiftpm-compatible-brightgreen.svg?style=flat" alt="Swift Package Manager" />
    </a>
</p>

Welcome to **Pack**, a Swift package to serialize and deserialize values into an external binary representation.

Pack is similar in purpose to the built-in `Codable` protocols, but unlike `Codable` it is not key/value based. The layout of the bytes is described by the code that writes them, and that layout *is* the format — which makes Pack suited to reading and writing binary file formats, and to storing data compactly.

Every decision that affects the bytes on disk is made explicitly: the byte order, the width of every integer, and the encoding and framing of every string. None of it is inherited from the machine the code happens to be running on.

## Usage

### Basic packing and unpacking

A `Packer` writes values into an external representation. `BinaryPacker` is the built-in packer for Swift's primitive types.

```swift
var packer = BinaryPacker(configuration: .littleEndian)

try packer.pack(Int64(12345))
try packer.pack(6789.0)
try packer.pack("Hello, world!", using: .utf8)

let data = packer.data
```

Reading back uses a `BinaryUnpacker` with the same configuration.

```swift
var unpacker = BinaryUnpacker(from: data, configuration: .littleEndian)

let int = try unpacker.unpack(Int64.self)
let double = try unpacker.unpack(Double.self)
let string = try unpacker.unpack(String.self, using: .utf8)
```

A configuration has no default byte order — you name one, or you do not get a packer. There is no process-wide state that could change how a file is written.

### Extending types to be Packable and Unpackable

Any type can conform to `Packable` to describe how it is serialized, and `Unpackable` to describe how it is read back. `Packed` is shorthand for both.

```swift
struct Color {
    let name: String
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double = 1.0
}

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

The packer is a generic parameter rather than an existential, so packing a value compiles down to direct calls on the concrete packer instead of dispatching dynamically for every field. Where the packer's type genuinely cannot be known — dispatching through a class-bound existential, or calling a closure captured before any packer existed — wrap it in `AnyPacker`, which is a concrete type and so satisfies the generic parameter.

### Framing

A format usually needs to record how long something is before it has been written. `withLengthPrefix` reserves the length, packs the body, then fills the length in.

```swift
try packer.pack("MESH", using: .ascii, framing: .fixed(byteCount: 4))
try packer.withLengthPrefix(.uint64) { packer in
    try packer.pack(mesh)
}
```

This produces the same bytes whatever the destination. A packer writing to memory patches the length in place; a packer writing to a stream, which cannot revise output it has already handed over, buffers the body until the length is known. Both paths run the same encoding code, so the file does not depend on how it was written.

Reading back, `withLimit` bounds a span. Reads are checked against the limit as they happen, so a length that does not match its contents is reported rather than allowed to run on into whatever follows. Anything in the span that was not read is skipped, which is what lets an older reader accept a span that a newer writer has added fields to.

```swift
let length = try unpacker.unpack(UInt64.self)

try unpacker.withLimit(byteCount: Int(length)) { unpacker in
    // read the fields this version knows about; the rest is skipped
}
```

### Strings

How a string records its extent is chosen per field, because one format routinely mixes several — a fixed-size tag, a length-prefixed name, a null-terminated path.

```swift
try packer.pack(tag,  using: .ascii, framing: .fixed(byteCount: 4))
try packer.pack(name, using: .utf8,  framing: .lengthPrefixed(.uint32))
try packer.pack(path, using: .utf8,  framing: .nullTerminated)
```

The configuration supplies a default so the common case stays short.

### Collections

Arrays of scalars pack in a single pass, and reduce to a bulk copy when no reordering is needed.

```swift
try packer.pack(contentsOf: vertices)
try packer.pack(contentsOf: indices, countPrefixedBy: .uint32)
```

### Reading and writing streams

Pack can serialize directly to an `OutputStream`, or read from an `InputStream`.

```swift
if let outputStream = OutputStream(toFileAtPath: myFilePath, append: false) {
    outputStream.open()
    var packer = BinaryPacker(writingTo: outputStream, configuration: .littleEndian)
    try packer.pack("Hello, World!", using: .ascii)
}
```

```swift
if let inputStream = InputStream(fileAtPath: myFilePath) {
    inputStream.open()
    var unpacker = BinaryUnpacker(readingFrom: inputStream, configuration: .littleEndian)
    let string = try unpacker.unpack(String.self, using: .ascii)
}
```

Other destinations and sources — a memory mapped file, a socket, a compressing sink — are a four-method conformance to `PackDestination` or `UnpackSource`, and need no changes to the encoding.

## Limitations

Pack is intended for serializing raw binary data, so the layout of packed data matters. Beyond the primitive built-in types, Pack provides no automatic conformance for complex Swift types — adding it is left to the caller, so that the data is written in a stable format matching the use case.

`Int` and `UInt` change width between platforms, so a file written with them is readable only on a machine of matching width — and would not fail on the machine it was tested on. Pack's integer APIs are constrained to `PortableInteger`, which `Int` and `UInt` deliberately do not conform to, so using one is a compile error rather than a corrupt file discovered later. Widen explicitly:

```swift
try packer.pack(Int64(value))
```

## Installation

Pack is distributed using the [Swift Package Manager](https://swift.org/package-manager). To install it within another Swift package, add it as a dependency within your `Package.swift` manifest:

```swift
let package = Package(
    // . . .
    dependencies: [
        .package(url: "https://github.com/mattcox/Pack.git", branch: "main")
    ],
    // . . .
)
```

If you’d like to use Pack within an application on Apple platforms, then use Xcode’s `File > Add Packages...` menu command to add it to your project.

Import Pack wherever you’d like to use it:
```swift
import Pack
```

Pack requires a Swift 6 toolchain, and builds in Swift 6 language mode.
