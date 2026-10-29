/* ringbuf: fixed-size byte FIFO without allocation (ISR producer, main-loop consumer). */
#ifndef RINGBUF_H
#define RINGBUF_H
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#ifdef __cplusplus
extern "C" {
#endif
#define RINGBUF_CAP 16u /* power of two */
typedef struct { uint8_t data[RINGBUF_CAP]; volatile uint16_t head, tail; } ringbuf_t;
void ringbuf_init(ringbuf_t *rb);
bool ringbuf_put(ringbuf_t *rb, uint8_t b);   /* false when full */
bool ringbuf_get(ringbuf_t *rb, uint8_t *b);  /* false when empty */
size_t ringbuf_count(const ringbuf_t *rb);
#ifdef __cplusplus
}
#endif
#endif
