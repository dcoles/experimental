# BusyBox

A BusyBox SquashApp.

It can be built and run as follows:

```bash
# Optional: Fetch a BusyBox binary
curl -o examples/busybox/bin/busybox https://www.busybox.net/downloads/binaries/1.31.0-defconfig-multiarch-musl/busybox-x86_64

./build_squashapp --embed examples/busybox
./busybox.run
```
