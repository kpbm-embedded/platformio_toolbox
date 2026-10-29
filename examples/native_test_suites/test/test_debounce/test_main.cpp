#include <unity.h>
#include "control.h"

void setUp() {}
void tearDown() {}

static void test_needs_stable_samples() {
    Debounce d;
    debounce_init(&d, 3, false);
    TEST_ASSERT_FALSE(debounce_update(&d, true));
    TEST_ASSERT_FALSE(debounce_update(&d, true));
    TEST_ASSERT_TRUE(debounce_update(&d, true));
}
static void test_glitch_ignored() {
    Debounce d;
    debounce_init(&d, 3, false);
    debounce_update(&d, true);
    debounce_update(&d, false);   // bounce resets the count
    debounce_update(&d, true);
    TEST_ASSERT_FALSE(debounce_update(&d, true));
    TEST_ASSERT_TRUE(debounce_update(&d, true));
}
static void test_release() {
    Debounce d;
    debounce_init(&d, 2, true);
    debounce_update(&d, false);
    TEST_ASSERT_FALSE(debounce_update(&d, false));
}

int runUnityTests() {
    UNITY_BEGIN();
    RUN_TEST(test_needs_stable_samples);
    RUN_TEST(test_glitch_ignored);
    RUN_TEST(test_release);
    return UNITY_END();
}
#ifdef ARDUINO
#include <Arduino.h>
void setup() { delay(2000); runUnityTests(); }
void loop() {}
#else
int main() { return runUnityTests(); }
#endif
