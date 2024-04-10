# ``Pack/BinaryPack/Options-swift.struct/stringsNullTerminated``

Strings being unpacked will stop unpacking when the null terminator is reached.

![An example of a null terminated string.](stringsNullTerminated.png)

Packing and unpacking strings with a null terminator can be slow in some
instances. For better performance, use ``stringsPrependedWithSize``.

> Important: When null terminating strings, the choices for string encoding
is limited to `ascii` and `utf8`.
