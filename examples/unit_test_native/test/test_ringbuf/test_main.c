#include <unity.h>
#include "ringbuf.h"

static ringbuf_t rb;
void setUp(void) { ringbuf_init(&rb); }
void tearDown(void) {}

static void test_empty(void) {
    uint8_t b;
    TEST_ASSERT_EQUAL_UINT(0, ringbuf_count(&rb));
    TEST_ASSERT_FALSE(ringbuf_get(&rb, &b));
}
static void test_fifo_order(void) {
    uint8_t b;
    for (uint8_t i = 0; i < 5; i++) TEST_ASSERT_TRUE(ringbuf_put(&rb, i));
    for (uint8_t i = 0; i < 5; i++) { TEST_ASSERT_TRUE(ringbuf_get(&rb, &b)); TEST_ASSERT_EQUAL_UINT8(i, b); }
}
static void test_full(void) {
    for (unsigned i = 0; i < RINGBUF_CAP; i++) TEST_ASSERT_TRUE(ringbuf_put(&rb, (uint8_t)i));
    TEST_ASSERT_FALSE(ringbuf_put(&rb, 0xAA));
    TEST_ASSERT_EQUAL_UINT(RINGBUF_CAP, ringbuf_count(&rb));
}
static void test_wraparound(void) {
    uint8_t b;
    for (unsigned round = 0; round < 70000u; round++) {   /* index counters wrap past 65535 */
        TEST_ASSERT_TRUE(ringbuf_put(&rb, (uint8_t)round));
        TEST_ASSERT_TRUE(ringbuf_get(&rb, &b));
        TEST_ASSERT_EQUAL_UINT8((uint8_t)round, b);
    }
    TEST_ASSERT_EQUAL_UINT(0, ringbuf_count(&rb));
}

int main(void) {
    UNITY_BEGIN();
    RUN_TEST(test_empty);
    RUN_TEST(test_fifo_order);
    RUN_TEST(test_full);
    RUN_TEST(test_wraparound);
    return UNITY_END();
}
