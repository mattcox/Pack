# ``Pack/BinaryPack/Options-swift.struct/stringsPrependedWithSize``

The size string doesn't describe the number of characters in the string, but
instead describes the number of bytes in the string. For `ascii` this will
match the number of characters, but for more complex encodings, this may be
greater-than or less-than the number of characters.

![An example of a string prepended with a size.](stringsPrependedWithSize.png)

> Warning: When writing out strings greater in length than `Int32.max`, a
different method for marking the length of the string should be used, such as
``stringsNullTerminated``.
