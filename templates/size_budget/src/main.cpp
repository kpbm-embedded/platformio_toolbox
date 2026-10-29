// @NAME@ (size_budget template): a sketch of known size (Serial + a small lookup table).
#include <Arduino.h>
static const uint8_t gamma8[32] = {0, 0, 0, 1, 1, 2, 3, 4, 6, 8, 10, 13, 16, 19, 23, 27,
                                   32, 37, 43, 49, 56, 63, 71, 80, 89, 99, 110, 121, 133, 146, 159, 173};
void setup() { Serial.begin(115200); }
void loop() {
    for (uint8_t i = 0; i < 32; i++) Serial.println(gamma8[i]);
    delay(1000);
}
