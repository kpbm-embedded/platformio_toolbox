// @NAME@ (extra_scripts template): FW_VERSION and FW_ENV come from scripts/version.py (pre-script).
#include <Arduino.h>
static const char version_string[] = "fw " FW_VERSION " env " FW_ENV;
void setup() { Serial.begin(115200); }
void loop() {
    Serial.println(version_string);
    delay(1000);
}
