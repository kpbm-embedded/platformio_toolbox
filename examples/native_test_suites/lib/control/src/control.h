// control: a fixed-point PI controller and a debouncer, no dynamic memory, no floats.
#pragma once
#include <stdint.h>

struct Pi {             // gains in Q8 (256 = 1.0); output clamped to [out_min, out_max]
    int32_t kp_q8, ki_q8, out_min, out_max;
    int32_t integral;
};
void pi_reset(Pi *pi);
int32_t pi_step(Pi *pi, int32_t setpoint, int32_t measured);

struct Debounce {       // a level must be stable for `samples` calls before it is accepted
    uint8_t samples, count;
    bool state, candidate;
};
void debounce_init(Debounce *d, uint8_t samples, bool initial);
bool debounce_update(Debounce *d, bool raw);   // returns the debounced state
