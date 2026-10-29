#include "control.h"

void pi_reset(Pi *pi) { pi->integral = 0; }

int32_t pi_step(Pi *pi, int32_t setpoint, int32_t measured) {
    const int32_t error = setpoint - measured;
    const int32_t proportional = (pi->kp_q8 * error) / 256;
    const int32_t next_integral = pi->integral + (pi->ki_q8 * error) / 256;
    int32_t out = proportional + next_integral;
    if (out > pi->out_max) out = pi->out_max;          // anti-windup: integrate only when not saturated
    else if (out < pi->out_min) out = pi->out_min;
    else pi->integral = next_integral;
    return out;
}

void debounce_init(Debounce *d, uint8_t samples, bool initial) {
    d->samples = samples; d->count = 0; d->state = initial; d->candidate = initial;
}

bool debounce_update(Debounce *d, bool raw) {
    if (raw == d->state) { d->count = 0; d->candidate = raw; return d->state; }
    if (raw != d->candidate) { d->candidate = raw; d->count = 0; }
    if (++d->count >= d->samples) { d->state = raw; d->count = 0; }
    return d->state;
}
