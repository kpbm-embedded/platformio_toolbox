#include "ringbuf.h"

void ringbuf_init(ringbuf_t *rb) { rb->head = rb->tail = 0; }

size_t ringbuf_count(const ringbuf_t *rb) { return (uint16_t)(rb->head - rb->tail); }

bool ringbuf_put(ringbuf_t *rb, uint8_t b) {
    if (ringbuf_count(rb) >= RINGBUF_CAP) return false;
    rb->data[rb->head & (RINGBUF_CAP - 1u)] = b;
    rb->head++;
    return true;
}

bool ringbuf_get(ringbuf_t *rb, uint8_t *b) {
    if (ringbuf_count(rb) == 0) return false;
    *b = rb->data[rb->tail & (RINGBUF_CAP - 1u)];
    rb->tail++;
    return true;
}
