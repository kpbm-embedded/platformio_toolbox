// Firmware side (Arduino envs): bytes from Serial go through the ring buffer and back.
#ifdef ARDUINO
#include <Arduino.h>
#include "ringbuf.h"
static ringbuf_t rb;
void setup() { Serial.begin(115200); ringbuf_init(&rb); }
void loop() {
  while (Serial.available() > 0 && ringbuf_put(&rb, (uint8_t)Serial.read())) { }
  uint8_t b;
  while (ringbuf_get(&rb, &b)) Serial.write(b);
}
#endif
