// box_zig.h: C view of zig/box_zig.zig (keep the two in step).
#pragma once
#include <stddef.h>
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
uint16_t box_crc16_modbus(const uint8_t *data, size_t len);
uint32_t box_adc_to_mv(uint32_t raw, uint32_t adc_max, uint32_t vref_mv);
uint8_t box_popcount32(uint32_t mask);
#ifdef __cplusplus
}
#endif
