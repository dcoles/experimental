#include "endian.h"

uint16_t read_u16be(const uint8_t data[2])
{
    return  ((uint16_t) data[0] << 8) |
            ((uint16_t) data[1] << 0);
}

uint16_t read_u16le(const uint8_t data[2])
{
    return  ((uint16_t) data[0] << 0) |
            ((uint16_t) data[1] << 8);
}

uint32_t read_u32be(const uint8_t data[4])
{
    return  ((uint32_t) data[0] << 24) |
            ((uint32_t) data[1] << 16) |
            ((uint32_t) data[2] <<  8) |
            ((uint32_t) data[3] <<  0);
}

uint32_t read_u32le(const uint8_t data[4])
{
    return  ((uint32_t) data[0] <<  0) |
            ((uint32_t) data[1] <<  8) |
            ((uint32_t) data[2] << 16) |
            ((uint32_t) data[3] << 24);
}

uint64_t read_u64be(const uint8_t data[8])
{
    return  ((uint64_t) data[0] << 56) |
            ((uint64_t) data[1] << 48) |
            ((uint64_t) data[2] << 40) |
            ((uint64_t) data[3] << 32) |
            ((uint64_t) data[4] << 24) |
            ((uint64_t) data[5] << 16) |
            ((uint64_t) data[6] <<  8) |
            ((uint64_t) data[7] <<  0);
}

uint64_t read_u64le(const uint8_t data[8])
{
    return  ((uint64_t) data[0] <<  0) |
            ((uint64_t) data[1] <<  8) |
            ((uint64_t) data[2] << 16) |
            ((uint64_t) data[3] << 24) |
            ((uint64_t) data[4] << 32) |
            ((uint64_t) data[5] << 40) |
            ((uint64_t) data[6] << 48) |
            ((uint64_t) data[7] << 56);
}
