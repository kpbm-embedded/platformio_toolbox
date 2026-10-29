// @NAME@ (zig_lib template): C++ calling the Zig functions (include/box_zig.h).
#include "box_zig.h"
static const uint8_t frame[] = {'1', '2', '3', '4', '5', '6', '7', '8', '9'};

#ifdef ARDUINO
#include <Arduino.h>
void setup() { Serial.begin(115200); }
void loop() {
    Serial.printf("crc=0x%04X mv=%lu\n", box_crc16_modbus(frame, sizeof frame),
                  (unsigned long)box_adc_to_mv(analogRead(A0), 4095, 3300));
    delay(500);
}
#elif !defined(PIO_UNIT_TESTING)
#include <cstdio>
int main() {
    std::printf("crc16_modbus=0x%04X\n", box_crc16_modbus(frame, sizeof frame));
    return 0;
}
#endif
