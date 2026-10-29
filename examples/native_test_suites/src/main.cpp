// native_test_suites: the firmware entry points are left out of test builds (PIO_UNIT_TESTING).
#ifndef PIO_UNIT_TESTING
#include "app.h"
#include "control.h"
#ifdef ARDUINO
#include <Arduino.h>
static Pi pi{512, 32, 0, 255, 0};
void setup() { Serial.begin(115200); }
void loop() {
    Serial.println(pi_step(&pi, app_setpoint_after_presses(2), analogRead(A0) / 16));
    delay(100);
}
#else
#include <cstdio>
int main() {
    Pi pi{512, 32, 0, 255, 0};
    std::printf("%ld\n", static_cast<long>(pi_step(&pi, app_setpoint_after_presses(2), 20)));
    return 0;
}
#endif
#endif
