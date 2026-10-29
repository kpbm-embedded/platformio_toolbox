// @NAME@ (esp32_fs template): mount LittleFS (the "spiffs" data partition) and print the files and the
// running OTA slot.
#include <Arduino.h>
#include <LittleFS.h>
#include <esp_ota_ops.h>

void setup() {
    Serial.begin(115200);
    const esp_partition_t *running = esp_ota_get_running_partition();
    Serial.printf("running from %s at 0x%lx\n", running->label, (unsigned long)running->address);
    if (!LittleFS.begin(false)) { Serial.println("LittleFS mount failed (run -t uploadfs)"); return; }
    File root = LittleFS.open("/");
    for (File f = root.openNextFile(); f; f = root.openNextFile()) Serial.printf("%s %u bytes\n", f.name(), (unsigned)f.size());
    File config = LittleFS.open("/config.json");
    if (config) Serial.println(config.readString());
}
void loop() { delay(1000); }
