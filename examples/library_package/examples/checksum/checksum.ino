// box-crc example: CRC-16 of a line typed on the serial port.
#include <Arduino.h>
#include <box_crc.h>
void setup() { Serial.begin(115200); }
void loop() {
    static char line[64];
    static size_t used = 0;
    while (Serial.available()) {
        char c = (char)Serial.read();
        if (c == '\n' || used == sizeof line - 1) {
            Serial.print("crc16=0x");
            Serial.println(box_crc16_ccitt((const uint8_t *)line, used), HEX);
            used = 0;
        } else {
            line[used++] = c;
        }
    }
}
