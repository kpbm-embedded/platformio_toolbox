// Unity tests of the Zig library through its C ABI.
#include <unity.h>
#include "box_zig.h"

void setUp() {}
void tearDown() {}

static void test_crc() {
    const uint8_t check[] = {'1', '2', '3', '4', '5', '6', '7', '8', '9'};
    TEST_ASSERT_EQUAL_HEX16(0x4B37, box_crc16_modbus(check, sizeof check));
    TEST_ASSERT_EQUAL_HEX16(0, box_crc16_modbus(nullptr, 4));
}
static void test_adc() {
    TEST_ASSERT_EQUAL_UINT32(0, box_adc_to_mv(0, 4095, 3300));
    TEST_ASSERT_EQUAL_UINT32(3300, box_adc_to_mv(4095, 4095, 3300));
    TEST_ASSERT_EQUAL_UINT32(0, box_adc_to_mv(5, 0, 3300));
}
static void test_popcount() {
    TEST_ASSERT_EQUAL_UINT8(0, box_popcount32(0));
    TEST_ASSERT_EQUAL_UINT8(32, box_popcount32(0xFFFFFFFFu));
    TEST_ASSERT_EQUAL_UINT8(3, box_popcount32(0x80000101u));
}

int main() {
    UNITY_BEGIN();
    RUN_TEST(test_crc);
    RUN_TEST(test_adc);
    RUN_TEST(test_popcount);
    return UNITY_END();
}
