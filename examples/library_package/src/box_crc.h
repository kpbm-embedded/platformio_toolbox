// box-crc: bitwise CRCs (no tables: small flash, fine for short frames).
#ifndef BOX_CRC_H
#define BOX_CRC_H
#include <stddef.h>
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
uint8_t box_crc8_smbus(const uint8_t *data, size_t len);        // poly 0x07, init 0x00
uint16_t box_crc16_ccitt(const uint8_t *data, size_t len);      // poly 0x1021, init 0xFFFF
uint32_t box_crc32(const uint8_t *data, size_t len);            // reflected 0xEDB88320, init/xorout 0xFFFFFFFF
#ifdef __cplusplus
}
#endif
#endif
