# FreeBSD lsblk

A work-in-progress lsblk utility for FreeBSD aimed to be as Linux-compatible as possible.

The command line arguments are not implemented yet. Currently just runs as is.

At the moment the RM (Removable) column isn't implementable unless someone can give me advice or contribute a change for it.

Maj/Min *will not* be supported since FreeBSD has already abstracted away the need for those old-school Unix numbers.

Written in Zig as a preference language since:
* It's relatively easy to integrate with FreeBSD's base libraries without bindings.
* I'm using it as a learning tool for the base libraries.
