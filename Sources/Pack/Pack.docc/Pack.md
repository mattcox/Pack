# ``Pack``

Serialize and deserialize various data types into an external binary representation.

## Overview

Pack provides types and protocols for encoding and decoding various data types into external binary representations. This can be useful for storing data efficiently on disk, or for transmission across a network.

Different methods for packing and unpacking data can be provided by conforming to the ``Packer`` and ``Unpacker`` protocols, however a built-in ``BinaryPack`` object can pack primitive types such as `Int`, `Float` and `String` into their _in memory_ representation of the data. Additionally, Pack provides the ``Packable`` and ``Unpackable`` protocols, enabling support for encoding and decoding to be added to any Swift type.

Pack is similar in functionality to the built-in `Codable` protocols, however, unlike `Codable`, Pack is not key/value based, and is primarily intend for packing and unpacking binary data for efficient storage and transmission.

![A structure being packed into binary, and being unpacked from binary.](pack.png)

## Topics

### Packing Data
- ``BinaryPack``

### Custom Types
- ``Packed``
- ``Packable``
- ``Unpackable``

### Packer and Unpacker
- ``Packer``
- ``Unpacker``
