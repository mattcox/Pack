# ``Pack/BinaryPack``

Primitive types packed using the `BinaryPack` object are packed with their
memory layout matching the runtime memory layout of the specified type,
wherever possible. For example, an `Int8` type is packed as a single byte
(8 bits), whereas an `Int16` is packed as 4 bytes (16 bits) of contiguous
memory.

![An example of how memory is packed using BinaryPack.](binaryPack.png)

## Example

Primitive types can be packed and unpacked directly using a BinaryPack
object.

```swift
var packer = BinaryPack()
try packer.pack(1)
try packer.pack(2.0)
try packer.pack("3.0", using: .utf8)

let data = try packer.data

var unpacker = BinaryPack(with: data)
let int = try packer.unpack(Int.self)			// 1
let double = try packer.unpack(Double.self)		// 2.0
let string = try packer.unpack(String.self, using: .utf8)	// "3.0"
```

> Warning: Modifying the behaviour or memory layout of the BinaryPacker
after data has been packed will result in loss of data.
