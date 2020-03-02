# Handy Commands

## Logs
### Slicing by timestamp

```bash
sed -n '/2015-04-22 17:21:46/,/2015-04-22 17:21:50/p' ${FILE}
```

## Tracing
### Who sent `SIGKILL`

Using [tpoint](https://github.com/brendangregg/perf-tools/blob/master/system/tpoint) ([perf-tools](https://github.com/brendangregg/perf-tools)):

```bash
tpoint signal:signal_generate 'sig==9'
```

### Tracing `malloc`/`free`

Requires `libunwind`

```bash
ltrace -w 10 -l libc -e malloc -e free -p ${PID}
```

## Debugging
### GDB full backtrace

```bash
gdb --core ${CORE} -batch \
    -ex 'bt' \
    -ex 'echo \nProcess:\n' -ex 'info proc' \
    -ex 'echo \nLibraries:\n' -ex 'info sharedlib' \
    -ex 'echo \nMemory map:' -ex 'info target' \
    -ex 'echo \nRegisters:\n' -ex 'info register' \
    -ex 'echo \nCurrent instruction:\n' -ex 'x/16i $pc' \
    -ex 'echo \nThreads:\n' -ex 'info threads' \
    -ex 'echo \nAll threads:\n' -ex 'thread apply all bt'
```

### GDB debug symbols

Remember `--init-eval` for `safe-path`/`debug-file-directory`

```
set debug-file-directory <path>
```

### GDB core dump

```gdb
generate-core-file
```

### Debug malloc

See [mallopt(3)](http://man7.org/linux/man-pages/man3/mallopt.3.html)

```bash
MALLOC_CHECK=$((1|2|4))  # 1: print, 2: abort, 3: simplified
MALLOC_PERTURB_=1
```

## Misc
### Add URI handler

For MIME-type `x-scheme-handler/foo`:

```bash
xdg-mime default foo.desktop x-scheme-handler/foo
```

### `ch(r)oot`

```bash
if [[ -z "${UNSHARED}" ]]; then
    UNSHARED=1 exec unshare "$0" "$@"
fi
```

### Adding new device ID to driver

```bash
echo "8086 10f5" > /sys/bus/pci/drivers/uio_pci_generic/new_id
```

### SATA secure erase

```bash
hdparm -I  # must not be frozen
hdparm --user-master u --security-set-pass Eins ${DISK}
hdparm --user-master u --secure-erase Eins ${DISK}
```
