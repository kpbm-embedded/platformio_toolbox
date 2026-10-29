#include <unity.h>
#include "control.h"

void setUp() {}
void tearDown() {}

static void test_proportional_only() {
    Pi pi{256, 0, -1000, 1000, 0};
    TEST_ASSERT_EQUAL_INT32(10, pi_step(&pi, 30, 20));
}
static void test_integral_accumulates() {
    Pi pi{0, 128, -1000, 1000, 0};
    pi_step(&pi, 10, 0);
    TEST_ASSERT_EQUAL_INT32(10, pi_step(&pi, 10, 0));
}
static void test_clamp_and_anti_windup() {
    Pi pi{256, 256, 0, 100, 0};
    for (int i = 0; i < 50; i++) TEST_ASSERT_EQUAL_INT32(100, pi_step(&pi, 1000, 0));
    TEST_ASSERT_EQUAL_INT32(0, pi.integral);   // no windup while saturated
}
static void test_reset() {
    Pi pi{0, 256, -1000, 1000, 0};
    pi_step(&pi, 5, 0);
    pi_reset(&pi);
    TEST_ASSERT_EQUAL_INT32(0, pi.integral);
}

int runUnityTests() {
    UNITY_BEGIN();
    RUN_TEST(test_proportional_only);
    RUN_TEST(test_integral_accumulates);
    RUN_TEST(test_clamp_and_anti_windup);
    RUN_TEST(test_reset);
    return UNITY_END();
}
#ifdef ARDUINO
#include <Arduino.h>
void setup() { delay(2000); runUnityTests(); }
void loop() {}
#else
int main() { return runUnityTests(); }
#endif
