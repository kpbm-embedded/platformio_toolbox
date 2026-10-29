// Host unit test for @NAME@: ./pio-box utest . -e native
#include <unity.h>
void setUp(void) {}
void tearDown(void) {}
static int add(int a, int b) { return a + b; }
static void test_add(void) { TEST_ASSERT_EQUAL_INT(5, add(2, 3)); }
int main(void) { UNITY_BEGIN(); RUN_TEST(test_add); return UNITY_END(); }
