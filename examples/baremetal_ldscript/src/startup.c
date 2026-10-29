/* Minimal Cortex-M4 startup: copy .data, zero .bss, call main. Unused vectors go to Default_Handler. */
#include <stdint.h>

extern uint32_t _sidata, _sdata, _edata, _sbss, _ebss, _estack;
int main(void);

void Reset_Handler(void) {
    uint32_t *src = &_sidata, *dst = &_sdata;
    while (dst < &_edata) *dst++ = *src++;
    for (dst = &_sbss; dst < &_ebss;) *dst++ = 0;
    main();
    for (;;) {}
}
void Default_Handler(void) { for (;;) {} }
void SysTick_Handler(void);

__attribute__((section(".isr_vector"), used))
static void (*const vectors[16])(void) = {
    (void (*)(void))(&_estack), Reset_Handler,
    Default_Handler, Default_Handler, Default_Handler, Default_Handler, Default_Handler,   /* NMI..UsageFault */
    0, 0, 0, 0,
    Default_Handler, Default_Handler, 0, Default_Handler,                                 /* SVC, DebugMon, PendSV */
    SysTick_Handler,
};
