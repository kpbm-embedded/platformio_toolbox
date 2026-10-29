// lib_deps_json: read a JSON config (from Serial on a board, a constant on the host) and echo it back.
#include "device_config.h"
static const char default_config[] = R"({"name":"adc0","rate_hz":100,"channels":[0,1,4]})";

#ifdef ARDUINO
#include <Arduino.h>
void setup() {
    Serial.begin(115200);
    DeviceConfig config{};
    char out[128];
    if (parse_config(default_config, &config) == ConfigError::ok && write_config(config, out, sizeof out)) Serial.println(out);
}
void loop() { delay(1000); }
#elif !defined(PIO_UNIT_TESTING)
#include <cstdio>
int main() {
    DeviceConfig config{};
    char out[128];
    if (parse_config(default_config, &config) != ConfigError::ok) return 1;
    write_config(config, out, sizeof out);
    std::puts(out);
    return 0;
}
#endif
