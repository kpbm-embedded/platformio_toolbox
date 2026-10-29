// @NAME@ (static_check template): code that passes cppcheck and clang-tidy (the `clean` gate).
// No system headers in the analysed part (see platformio.ini): compiler built-in type macros instead.
using size_t = decltype(sizeof 0);
using uint16_t = __UINT16_TYPE__;
using uint32_t = __UINT32_TYPE__;

static uint16_t average(const uint16_t *samples, size_t count) {
    if (samples == nullptr || count == 0) return 0;
    uint32_t sum = 0;
    for (size_t i = 0; i < count; i++) sum += samples[i];
    return (uint16_t)(sum / count);
}

#ifdef ARDUINO
#include <Arduino.h>
void setup() { Serial.begin(115200); }
void loop() {
    uint16_t samples[8];
    for (size_t i = 0; i < 8; i++) samples[i] = (uint16_t)analogRead(A0);
    Serial.println(average(samples, 8));
    delay(1000);
}
#else
int main() {
    const uint16_t samples[4] = {10, 20, 30, 40};
    return average(samples, 4) == 25 ? 0 : 1;
}
#endif
