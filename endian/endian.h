#ifndef ENDIAN_H_
#define ENDIAN_H_

#include <stdint.h>

uint16_t read_u16be(const uint8_t data[2]);
uint16_t read_u16le(const uint8_t data[2]);
uint32_t read_u32be(const uint8_t data[4]);
uint32_t read_u32le(const uint8_t data[4]);
uint64_t read_u64be(const uint8_t data[8]);
uint64_t read_u64le(const uint8_t data[8]);

#endif /* ENDIAN_H_ */
