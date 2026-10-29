// @NAME@ (multi_board template): everything board-specific comes from build_flags in platformio.ini.
#ifndef BOARD_TAG
#error "BOARD_TAG must come from platformio.ini"
#endif
static const char banner[] = "board=" BOARD_TAG " family=" FAMILY " fw=" FW_NAME;

#ifdef ARDUINO
#include <Arduino.h>
#if HAS_FDCAN
extern "C" const char fdcan_note[];
#endif
void setup() {
    Serial.begin(115200);
    pinMode(LED, OUTPUT);
    Serial.println(banner);
#if HAS_FDCAN
    Serial.println(fdcan_note);
#endif
}
void loop() {
    static bool on = false;
    on = !on;
    digitalWrite(LED, (on != LED_ACTIVE_LOW) ? HIGH : LOW);
    delay(500);
}
#else
#include <cstdio>
int main() { std::puts(banner); return 0; }
#endif
