#include "@NAME@.h"

uint8_t box_crc8_smbus(const uint8_t *data, size_t len) {
    uint8_t crc = 0;
    for (size_t i = 0; i < len; i++) {
        crc ^= data[i];
        for (int bit = 0; bit < 8; bit++) crc = (uint8_t)((crc & 0x80u) ? ((unsigned)crc << 1) ^ 0x07u : (unsigned)crc << 1);
    }
    return crc;
}

uint16_t box_crc16_ccitt(const uint8_t *data, size_t len) {
    uint16_t crc = 0xFFFFu;
    for (size_t i = 0; i < len; i++) {
        crc ^= (uint16_t)(data[i] << 8);
        for (int bit = 0; bit < 8; bit++) crc = (uint16_t)((crc & 0x8000u) ? ((unsigned)crc << 1) ^ 0x1021u : (unsigned)crc << 1);
    }
    return crc;
}

uint32_t box_crc32(const uint8_t *data, size_t len) {
    uint32_t crc = 0xFFFFFFFFu;
    for (size_t i = 0; i < len; i++) {
        crc ^= data[i];
        for (int bit = 0; bit < 8; bit++) crc = (crc & 1u) ? (crc >> 1) ^ 0xEDB88320u : crc >> 1;
    }
    return crc ^ 0xFFFFFFFFu;
}
