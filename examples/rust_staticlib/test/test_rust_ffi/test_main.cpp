// Unity tests of the Rust library through its C ABI (the same calls the firmware makes).
#include <unity.h>
#include "box_rust.h"

void setUp() {}
void tearDown() {}

static void test_fletcher16() {
    const uint8_t abcde[] = {'a', 'b', 'c', 'd', 'e'};
    TEST_ASSERT_EQUAL_HEX16(0xC8F0, box_fletcher16(abcde, sizeof abcde));
    TEST_ASSERT_EQUAL_HEX16(0, box_fletcher16(nullptr, 3));
}
static void test_ema() {
    BoxEma ema{0, 2, false};
    TEST_ASSERT_EQUAL_INT32(100, box_ema_update(&ema, 100));
    TEST_ASSERT_EQUAL_INT32(125, box_ema_update(&ema, 200));   // 100 + (100 >> 2)
    TEST_ASSERT_TRUE(ema.primed);
}
static void test_saturating_add() {
    TEST_ASSERT_EQUAL_INT16(32767, box_sat_add_i16(32000, 1000));
    TEST_ASSERT_EQUAL_INT16(-32768, box_sat_add_i16(-32000, -1000));
    TEST_ASSERT_EQUAL_INT16(5, box_sat_add_i16(2, 3));
}

int main() {
    UNITY_BEGIN();
    RUN_TEST(test_fletcher16);
    RUN_TEST(test_ema);
    RUN_TEST(test_saturating_add);
    return UNITY_END();
}
