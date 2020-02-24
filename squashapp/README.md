# SquashApp

A self-extracting SquashFS application builder.

## Requirements

- [`bash`](https://www.gnu.org/software/bash) (or compatible [`mksh`, `busybox`, ...])
- [`mksquashfs`](https://github.com/plougher/squashfs-tools)
- [`squashfuse`](https://github.com/vasi/squashfuse)


## Building a SquashApp

```bash
build_squashapp [options] <sourcedir> [<main>]
```

For example:

```bash
build_squashapp examples/helloworld/ bin/helloworld
```


# Running a SquashApp

Just run it like any ordinary executable!

```bash
./helloworld.run "${USER}"
```
