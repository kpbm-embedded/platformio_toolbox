// rust_staticlib: C++ calling the Rust functions (include/box_rust.h).
#include "box_rust.h"
static const uint8_t frame[] = {'a', 'b', 'c', 'd', 'e'};

#ifdef ARDUINO
#include <Arduino.h>
static BoxEma ema{0, 3, false};
void setup() { Serial.begin(115200); }
void loop() {
    Serial.print("fletcher16=0x");
    Serial.print(box_fletcher16(frame, sizeof frame), HEX);
    Serial.print(" ema=");
    Serial.println(box_ema_update(&ema, analogRead(A0)));
    delay(500);
}
#elif !defined(PIO_UNIT_TESTING)
#include <cstdio>
int main() {
    std::printf("fletcher16=0x%04X\n", box_fletcher16(frame, sizeof frame));
    return 0;
}
#endif
