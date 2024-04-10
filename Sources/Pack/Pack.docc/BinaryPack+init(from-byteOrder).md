# ``Pack/BinaryPack/init(from:byteOrder:)``

#### Byte Order

The byte order specified describes the endianness of the bytes being unpacked.

A big-endian system stores the most significant byte at the smallest memory
address, and the least significant byte at the largest. A little-endian
system stores the least-significant byte at the smallest address.

The individual variables are still read in the order specified, as are the bits\
of each byte, however the byte order within each variable is reversed.

![A Float with swapped bytes.](bitShifting.png)

For more information: [Endianness](https://en.wikipedia.org/wiki/Endianness)

> Note: Little-Endian byte order is most common on modern computing platforms,
however some file formats still use Big-Endian.

