// Check values from the CRC catalogue (reveng): CRC of the ASCII string "123456789".
#include <string.h>
#include <unity.h>
#include "@NAME@.h"

static const uint8_t check[] = "123456789";
void setUp(void) {}
void tearDown(void) {}

static void test_crc8(void) { TEST_ASSERT_EQUAL_HEX8(0xF4, box_crc8_smbus(check, 9)); }
static void test_crc16(void) { TEST_ASSERT_EQUAL_HEX16(0x29B1, box_crc16_ccitt(check, 9)); }
static void test_crc32(void) { TEST_ASSERT_EQUAL_HEX32(0xCBF43926u, box_crc32(check, 9)); }
static void test_empty(void) {
    TEST_ASSERT_EQUAL_HEX8(0x00, box_crc8_smbus(check, 0));
    TEST_ASSERT_EQUAL_HEX16(0xFFFF, box_crc16_ccitt(check, 0));
    TEST_ASSERT_EQUAL_HEX32(0x00000000u, box_crc32(check, 0));
}
static void test_detects_bit_flip(void) {
    uint8_t frame[9];
    memcpy(frame, check, sizeof frame);
    frame[4] ^= 0x10;
    TEST_ASSERT_NOT_EQUAL(0xCBF43926u, box_crc32(frame, sizeof frame));
}

int main(void) {
    UNITY_BEGIN();
    RUN_TEST(test_crc8);
    RUN_TEST(test_crc16);
    RUN_TEST(test_crc32);
    RUN_TEST(test_empty);
    RUN_TEST(test_detects_bit_flip);
    return UNITY_END();
}
