#include "endian.h"

#include <stdint.h>
#include <stdio.h>
#include <assert.h>

#define EXPECT(EXP) \
    do { if (!(EXP)) \
        fprintf(stderr, "ERROR: Expected: " #EXP " (%s:%d)\n", __FILE__, __LINE__); } \
    while (0)

static const uint8_t data[] = {0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08};

static void test_1(void)
{
    EXPECT(read_u16be(data) == 0x0102);
    EXPECT(read_u16le(data) == 0x0201);

    EXPECT(read_u32be(data) == 0x01020304);
    EXPECT(read_u32le(data) == 0x04030201);

    EXPECT(read_u64be(data) == 0x0102030405060708);
    EXPECT(read_u64le(data) == 0x0807060504030201);
}

int main(int argc, char* argv[])
{
    test_1();
    return 0;
}
