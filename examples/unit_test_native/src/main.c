/* Host program (env native) and firmware entry (Arduino envs use main.cpp-free setup via
 * the Arduino core: see the #ifdef). Echoes a fixed message through the ring buffer. */
#include <stdio.h>
#include "ringbuf.h"
#ifndef ARDUINO
int main(void) {
    ringbuf_t rb; uint8_t b; const char *msg = "ringbuf ok\n";
    ringbuf_init(&rb);
    for (const char *p = msg; *p; p++) ringbuf_put(&rb, (uint8_t)*p);
    while (ringbuf_get(&rb, &b)) putchar(b);
    return 0;
}
#endif
