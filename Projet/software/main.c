#include <stdint.h>
#include <stdbool.h>

#define FIN_ROT     (*(volatile uint32_t *)0x04003000u) /* mirror data_ready */
#define FIN_SL      (*(volatile uint32_t *)0x04003010u) /* data_ready */
#define DIR_ROT     (*(volatile uint32_t *)0x04003020u) /* SW page LSB */
#define START_ROT   (*(volatile uint32_t *)0x04003030u) /* SW page MSB */
#define START_SL    (*(volatile uint32_t *)0x04003040u) /* acquisition trigger */
#define MOTOR_RIGHT (*(volatile uint32_t *)0x04003050u) /* unused */
#define MOTOR_LEFT  (*(volatile uint32_t *)0x04003060u) /* op_sel = bits [9:8] */
#define LEDS_ADR    (*(volatile uint32_t *)0x04003070u) /* LEDs */
#define SW_ADR      (*(volatile uint32_t *)0x04003080u) /* page data */

static void delay_cycles(volatile uint32_t count)
{
    while (count--) {
    }
}

static void select_page(uint8_t page)
{
    START_ROT = (uint32_t)((page >> 1) & 0x1u);
    DIR_ROT = (uint32_t)(page & 0x1u);
    delay_cycles(32u);
}

static uint8_t read_page(uint8_t page)
{
    select_page(page);
    return (uint8_t)(SW_ADR & 0xFFu);
}

static bool trigger_and_wait_ready(void)
{
    uint32_t timeout = 300000u;

    START_SL = 1u;
    while (((FIN_SL & 0x1u) == 0u) && (timeout > 0u)) {
        timeout--;
    }
    START_SL = 0u;

    if (timeout == 0u) {
        return false;
    }

    timeout = 100000u;
    while (((FIN_SL & 0x1u) != 0u) && (timeout > 0u)) {
        timeout--;
    }

    return (timeout != 0u);
}

static uint16_t compute_expected(uint8_t data_ir, uint8_t data_jr, uint8_t op_sel)
{
    switch (op_sel & 0x3u) {
    case 0u:
        return (uint16_t)((uint16_t)data_ir + (uint16_t)data_jr);
    case 1u:
        return (uint16_t)((uint16_t)data_ir - (uint16_t)data_jr);
    case 2u:
        return (uint16_t)((uint16_t)data_ir << 1);
    default:
        return (uint16_t)((uint16_t)data_ir >> 1);
    }
}

int main(void)
{
    START_SL = 0u;
    START_ROT = 0u;
    DIR_ROT = 0u;
    MOTOR_RIGHT = 0u;

    while (1) {
        for (uint8_t op = 0u; op < 4u; op++) {
            uint8_t result_lo = 0u;
            uint8_t result_hi = 0u;
            uint8_t data_ir = 0u;
            uint8_t data_jr = 0u;
            uint16_t result_hw = 0u;
            uint16_t result_sw = 0u;
            bool ok = false;

            MOTOR_LEFT = ((uint32_t)(op & 0x3u) << 8);

            ok = trigger_and_wait_ready();
            if (!ok) {
                LEDS_ADR = (uint32_t)(0x80u | (op << 4));
                delay_cycles(200000u);
                continue;
            }

            result_lo = read_page(0u); /* {start_rot,dir_rot}=00 */
            result_hi = read_page(1u); /* {start_rot,dir_rot}=01 */
            data_ir = read_page(2u);   /* {start_rot,dir_rot}=10 */
            data_jr = read_page(3u);   /* {start_rot,dir_rot}=11 */

            result_hw = (uint16_t)(((uint16_t)result_hi << 8) | (uint16_t)result_lo);
            result_sw = compute_expected(data_ir, data_jr, op);

            if ((result_hw == result_sw) && ((FIN_ROT & 0x1u) == 0u)) {
                LEDS_ADR = (uint32_t)(result_lo);
            } else {
                LEDS_ADR = (uint32_t)(0x80u | (op << 4) | (result_lo & 0x0Fu));
            }

            delay_cycles(250000u);
        }
    }
}
