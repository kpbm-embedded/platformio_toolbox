// device_config: parse {"name":..,"rate_hz":..,"channels":[..]} with ArduinoJson; reject bad input.
#pragma once
#include <stddef.h>
#include <stdint.h>

struct DeviceConfig {
    char name[16];
    uint16_t rate_hz;
    uint8_t channels[8];
    uint8_t channel_count;
};
enum class ConfigError { ok, bad_json, missing_field, out_of_range };
ConfigError parse_config(const char *json, DeviceConfig *out);
size_t write_config(const DeviceConfig &config, char *buffer, size_t size);
