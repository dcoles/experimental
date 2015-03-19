/**
 * BPF Socket Example
 *
 * Author: David Coles <coles.david@gmail.com>
 *
 * See http://netsplit.com/the-proc-connector-and-socket-filters
 * for an excellent example.
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>

#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#include <linux/filter.h>

#define ERROR(FMT, ...) do { fprintf(stderr, "ERROR: " FMT "\n", ##__VA_ARGS__); } while (0)
#define INFO(FMT, ...) do { fprintf(stderr, "INFO: " FMT "\n", ##__VA_ARGS__); } while (0)

#define TARGET 0x41  // ASCII 'A'
#define FILTER 1  // Enable BPF
//#define HOST "127.0.0.1"
#define PORT 1234

struct sock_filter filter[] = {
    BPF_STMT (BPF_LD|BPF_B|BPF_ABS, 8),  // Load byte from offset 8 (sizeof(udp-header))
    BPF_JUMP (BPF_JMP|BPF_JEQ|BPF_K, TARGET, 1, 0),  // Jump 1 if byte == TARGET
    BPF_STMT (BPF_RET|BPF_K, 0x00000000),  // Reject
    BPF_STMT (BPF_RET|BPF_K, 0xFFFFFFFF),  // Accept
};

int main(int argc, char* argv[])
{
    // Open socket
    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock == -1) {
        ERROR("socket: %s (%d)", strerror(errno), errno);
        exit(1);
    }

    // Enable rebinding to the same port (SO_REUSEADDR should work for UDP too)
    int optarg = 1;
    if (setsockopt(sock, SOL_SOCKET, SO_REUSEPORT, &optarg, sizeof(optarg)) == -1) {
        ERROR("setsockopt: %s (%d)", strerror(errno), errno);
        exit(1);
    }

    // Bind to address
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(PORT);

#ifdef HOST
    INFO("Listening for UDP packets on %s:%d", HOST, PORT);
    if (inet_aton(HOST, &addr.sin_addr) == 0) {
        ERROR("inet_aton");
        exit(1);
    }
#else
    INFO("Listening for UDP packets on *:%d", PORT);
    addr.sin_addr.s_addr = INADDR_ANY;
#endif

    if (bind(sock, (struct sockaddr *) &addr, sizeof(addr)) == -1) {
        ERROR("socket: %s (%d)", strerror(errno), errno);
        exit(1);
    }

#if FILTER
    // Create filter
    struct sock_fprog fprog;
    memset(&fprog, 0, sizeof(fprog));
    fprog.filter = filter;
    fprog.len = sizeof(filter) / sizeof(filter[0]);

    INFO("Filtering packets for '%c'", TARGET);
    if (setsockopt(sock, SOL_SOCKET, SO_ATTACH_FILTER, &fprog, sizeof(fprog)) == -1) {
        ERROR("setsockopt: %s (%d)", strerror(errno), errno);
        exit(1);
    }
#endif


    // Print packets
    char buf[1500];
    while (1) {
        memset(buf, 0, sizeof(buf));
        ssize_t rsize = recv(sock, buf, sizeof(buf), 0);
        if (rsize == -1) {
            ERROR("recv: %s (%d)", strerror(errno), errno);
            exit(1);
        }

        printf("RECV: %s", buf);
        sleep(1);
    }

    return 0;
}
