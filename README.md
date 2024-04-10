# Pack

Welcome to **Pack**, a Swift package to serialize and deserialize various data types into an external representation.

Pack is similar in functionality to the built-in `Codable` protocols, however, unlike Codable, Pack is not key/value based, and as such is intend for packing and unpacking binary data for efficient storage.

## Usage

### Basic packing and unpacking
To serialize some data, a `Packer` is used to pack data into a Swift `Data` object. The `BinaryPack` object conforms to `Packer` and `Unpacker`, and encodes Swift primitive types.

```swift
// Initialize a new Packer
let packer = BinaryPack()

// Pack an Integer
try packer.pack(12345)

// Pack a Double
try packer.pack(6789.0)

// Pack a String with utf8 encoding
try packer.pack("Hello, world!", using: .utf8)
```

The data serialized by the Packer can be read as a Swift `Data` object.

```swift
let packedData = packer.data
```

Data can also be decoded using an `Unpacker`.

```swift
// Initialize a new Unpacker, and specify the data that should be unpacked
let unpacker = BinaryPack(from: data)

// Unpack an Integer
let int = try unpacker.unpack(Int.self)

// Unpack an Double
let double = try unpacker.unpack(Double.self)

// Unpack an String that was packed with utf8 encoding
let string = try unpacker.unpack(String.self, using: .utf8)
```

### Extending types to be Packable and Unpackable
Any type can conform to `Packable`, allowing it to be serialized. The type can also conform to `Unpackable` allowing to be deserialized. A type that conforms to `Packed`, is shorthand for `Packable` and `Unpackable`, and must conform to both.

For example, consider the following structure representing a named color.

```swift
struct Color {
    let name: String
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double = 1.0
}
```

To allow this struct to be serialized using a `Packer`, it must add conformance to `Packable`.

```swift
extension Color: Packable {
    func pack(to packer: inout Packer) throws {
        try packer.pack(name, using: .utf16)
        try packer.pack(red)
        try packer.pack(green)
        try packer.pack(blue)
        try packer.pack(alpha)
    }
}
```

The `pack(to:)` functions provides a Packer as an _inout_ variable, and the function is expected to call functions on the Packer to serialize its member variables.

To allow this struct to be deserialized using a `Unpacker`, it must add conformance to `Unpackable`.

```swift
extension Color: Unpackable {
    init(from unpacker: inout Unpacker) throws {
        self.name = try unpacker.unpack(String.self, using: .utf16)
        self.red = try unpacker.unpack(Double.self)
        self.green = try unpacker.unpack(Double.self)
        self.blue = try unpacker.unpack(Double.self)
        self.alpha = try unpacker.unpack(Double.self)
    }
}
```

The `init(from:)` initializer provides an Unpacker as an inout variable, and the function is expected to call functions on the Packer to deserialize its member variables.

### Reading and Writing from a Stream
Pack provides support for serialization and deserialization of a stream, for example writing to memory, or directly to a file.

```swift
if let outputSteam = OutputStream(toFileAtPath: myFilePath, append: false) {
    let packer = BinaryPack(writingTo: outputStream)
    try packer.pack("Hello, World!", using: .ascii)
}
```

Data can also be deserialized from an `InputStream`.

```swift
if let inputStream = InputStream(fileAtPath: myFilePath) {
    let unpacker = BinaryPack(readingFrom: inputStream)
    try unpacker.unpack(String.self, using: .ascii)
}
```

### BinaryPack Options
**BinaryPack** is the standard packer for serializing and deserializing Swift built-in types as binary data. By default, it writes the string byte size before the string data, ensuring it can easily be read back in.

This behaviour can be modified using options when initializing the BinaryPack object.

For example, to read or write a null terminator after strings, the following options can be set.

```swift
let binaryPack = BinaryPack(options: [.stringsNullTerminated])
```

## Limitations

As Pack is intended for serializing and deserializing raw binary data, the layout of packed data is important. As such, beyond primitive built-in value types, such as `Int`, `Double`, `String`...etc, Pack provides no support for packing or unpacking complex Swift built-in types. As such, adding Pack protocol conformance to more complex built-in types is left to the end user, allowing them to ensure the data is written out in a stable format that matches the use case.

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
