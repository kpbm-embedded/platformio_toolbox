// Tests code from src/ (test_build_src = yes); main.cpp drops its entry points under PIO_UNIT_TESTING.
#include <unity.h>
#include "app.h"

void setUp() {}
void tearDown() {}

static void test_default() { TEST_ASSERT_EQUAL_INT32(20, app_setpoint_after_presses(0)); }
static void test_steps() { TEST_ASSERT_EQUAL_INT32(35, app_setpoint_after_presses(3)); }
static void test_limit() { TEST_ASSERT_EQUAL_INT32(60, app_setpoint_after_presses(100)); }

int main() {
    UNITY_BEGIN();
    RUN_TEST(test_default);
    RUN_TEST(test_steps);
    RUN_TEST(test_limit);
    return UNITY_END();
}
