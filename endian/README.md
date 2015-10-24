# Handling Endian-ness in C

An attempt at putting into practice the ideas from Rob Pike's excellent blog-post
[The byte order fallacy](http://commandcenter.blogspot.com/2012/04/byte-order-fallacy.html).

The main issue that you end up encountering is when reading and writing values
larger than a C `int`. You need to ensure that you cast your values to the
correct size so that things like shift operations behave correctly.

There's also the question of how to design a reasonably safe API for reading and
writing from a sequence of bytes without accidentally causing a buffer overrun.
