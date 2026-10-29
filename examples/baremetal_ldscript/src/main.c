/* Register-level blink of PC13 (BlackPill LED, active low) from the 16 MHz HSI with SysTick at 1 kHz. */
#include <stdint.h>

#define REG(addr) (*(volatile uint32_t *)(addr))
#define RCC_AHB1ENR REG(0x40023830u)
#define GPIOC_MODER REG(0x40020800u)
#define GPIOC_ODR REG(0x40020814u)
#define SYST_CSR REG(0xE000E010u)
#define SYST_RVR REG(0xE000E014u)
#define SYST_CVR REG(0xE000E018u)

static volatile uint32_t ticks;
uint32_t blink_period_ms = 500;   /* in .data: checks that startup copies it */

void SysTick_Handler(void) { ticks++; }

int main(void) {
    RCC_AHB1ENR |= 1u << 2;                                       /* GPIOC clock */
    GPIOC_MODER = (GPIOC_MODER & ~(3u << 26)) | (1u << 26);       /* PC13 output */
    SYST_RVR = 16000u - 1u;                                       /* 16 MHz / 16000 = 1 kHz */
    SYST_CVR = 0;
    SYST_CSR = 7u;                                                /* enable, interrupt, core clock */
    uint32_t next = blink_period_ms;
    for (;;) {
        if ((int32_t)(ticks - next) >= 0) {
            GPIOC_ODR ^= 1u << 13;
            next += blink_period_ms;
        }
    }
}
