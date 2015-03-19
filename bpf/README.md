# Linux BPF Example

How to filter UDP packets using Linux Socket Filtering (a.k.a. BPF).

An alternative way of generating the `struct sock_filter` array contents is to
use tcpdump to generate the program (see the `-dd` option to `tcpdump` or
pcap_compile(3PCAP)).

## Links

- http://netsplit.com/the-proc-connector-and-socket-filters
- https://www.kernel.org/doc/Documentation/networking/filter.txt
- http://www.freebsd.org/cgi/man.cgi?bpf%28f%29 (see "Filter Machine" section)
