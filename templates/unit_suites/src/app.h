// app: turns button presses into a heater setpoint (logic only, testable on the host).
#pragma once
#include <stdint.h>
int32_t app_setpoint_after_presses(int presses);   // 20 C + 5 C per press, at most 60 C
