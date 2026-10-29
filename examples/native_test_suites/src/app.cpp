#include "app.h"
int32_t app_setpoint_after_presses(int presses) {
    const int32_t value = 20 + 5 * presses;
    return value > 60 ? 60 : value;
}
