#include <string.h>
#include <unity.h>
#include "device_config.h"

void setUp() {}
void tearDown() {}

static void test_parse_ok() {
    DeviceConfig c{};
    TEST_ASSERT_EQUAL(ConfigError::ok, parse_config(R"({"name":"adc0","rate_hz":250,"channels":[1,2,3]})", &c));
    TEST_ASSERT_EQUAL_STRING("adc0", c.name);
    TEST_ASSERT_EQUAL_UINT16(250, c.rate_hz);
    TEST_ASSERT_EQUAL_UINT8(3, c.channel_count);
    TEST_ASSERT_EQUAL_UINT8(3, c.channels[2]);
}
static void test_bad_json() {
    DeviceConfig c{};
    TEST_ASSERT_EQUAL(ConfigError::bad_json, parse_config("{\"name\":", &c));
}
static void test_missing_field() {
    DeviceConfig c{};
    TEST_ASSERT_EQUAL(ConfigError::missing_field, parse_config(R"({"name":"x","channels":[]})", &c));
}
static void test_out_of_range() {
    DeviceConfig c{};
    TEST_ASSERT_EQUAL(ConfigError::out_of_range, parse_config(R"({"name":"x","rate_hz":0,"channels":[]})", &c));
    TEST_ASSERT_EQUAL(ConfigError::out_of_range, parse_config(R"({"name":"x","rate_hz":5,"channels":[16]})", &c));
}
static void test_round_trip() {
    DeviceConfig c{}, back{};
    char buffer[128];
    parse_config(R"({"name":"a-very-long-device-name","rate_hz":10,"channels":[7]})", &c);
    TEST_ASSERT_EQUAL_STRING("a-very-long-dev", c.name);   // truncated to 15 chars
    TEST_ASSERT_TRUE(write_config(c, buffer, sizeof buffer) > 0);
    TEST_ASSERT_EQUAL(ConfigError::ok, parse_config(buffer, &back));
    TEST_ASSERT_EQUAL_MEMORY(&c, &back, sizeof c);
}

int main() {
    UNITY_BEGIN();
    RUN_TEST(test_parse_ok);
    RUN_TEST(test_bad_json);
    RUN_TEST(test_missing_field);
    RUN_TEST(test_out_of_range);
    RUN_TEST(test_round_trip);
    return UNITY_END();
}
