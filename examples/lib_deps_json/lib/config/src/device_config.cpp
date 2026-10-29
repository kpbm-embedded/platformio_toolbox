#include "device_config.h"
#include <ArduinoJson.h>
#include <string.h>

ConfigError parse_config(const char *json, DeviceConfig *out) {
    JsonDocument doc;
    if (deserializeJson(doc, json)) return ConfigError::bad_json;
    if (!doc["name"].is<const char *>() || !doc["rate_hz"].is<int>() || !doc["channels"].is<JsonArrayConst>())
        return ConfigError::missing_field;
    const int rate = doc["rate_hz"];
    JsonArrayConst channels = doc["channels"];
    if (rate < 1 || rate > 10000 || channels.size() > sizeof out->channels) return ConfigError::out_of_range;
    strncpy(out->name, doc["name"] | "", sizeof out->name - 1);
    out->name[sizeof out->name - 1] = '\0';
    out->rate_hz = static_cast<uint16_t>(rate);
    out->channel_count = 0;
    for (JsonVariantConst channel : channels) {
        const int value = channel.as<int>();
        if (value < 0 || value > 15) return ConfigError::out_of_range;
        out->channels[out->channel_count++] = static_cast<uint8_t>(value);
    }
    return ConfigError::ok;
}

size_t write_config(const DeviceConfig &config, char *buffer, size_t size) {
    JsonDocument doc;
    doc["name"] = config.name;
    doc["rate_hz"] = config.rate_hz;
    JsonArray channels = doc["channels"].to<JsonArray>();
    for (uint8_t i = 0; i < config.channel_count; i++) channels.add(config.channels[i]);
    return serializeJson(doc, buffer, size);
}
