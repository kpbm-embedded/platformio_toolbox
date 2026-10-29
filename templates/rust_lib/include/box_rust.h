// box_rust.h: C view of rust/src/lib.rs (keep the two in step).
#pragma once
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
typedef struct { int32_t value; uint8_t shift; bool primed; } BoxEma;
uint16_t box_fletcher16(const uint8_t *data, size_t len);
int32_t box_ema_update(BoxEma *ema, int32_t sample);
int16_t box_sat_add_i16(int16_t a, int16_t b);
#ifdef __cplusplus
}
#endif
