#include <stdint.h>
#include <stdbool.h>

#define FIN_ROT     (*(volatile uint32_t *)0x04003000u) /* line lost flag */
#define FIN_SL      (*(volatile uint32_t *)0x04003010u) /* data_ready */
#define DIR_ROT     (*(volatile uint32_t *)0x04003020u) /* SW mux select */
#define START_ROT   (*(volatile uint32_t *)0x04003030u) /* reserved */
#define START_SL    (*(volatile uint32_t *)0x04003040u) /* acquisition trigger */
#define MOTOR_RIGHT (*(volatile uint32_t *)0x04003050u) /* reserved */
#define MOTOR_LEFT  (*(volatile uint32_t *)0x04003060u) /* threshold[7:0] */
#define LEDS_ADR    (*(volatile uint32_t *)0x04003070u) /* LEDs */
#define SW_ADR      (*(volatile uint32_t *)0x04003080u) /* vect/position readback */

static void delay_cycles(volatile uint32_t count)
{
    while (count--) {
    }
}

static int compute_position_from_vect(uint8_t vect)
{
    int ppu = 0;
    int pdu = 0;
    bool found = false;

    for (int i = 0; i < 7; i++) {
        if ((vect & (1u << i)) != 0u) {
            ppu = i;
            found = true;
            break;
        }
    }
    if (!found) {
        ppu = 0;
    }

    found = false;
    for (int i = 6; i >= 0; i--) {
        if ((vect & (1u << i)) != 0u) {
            pdu = i;
            found = true;
            break;
        }
    }
    if (!found) {
        pdu = 0;
    }

    return (ppu + pdu - 6);
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

int main(void)
{
    const uint8_t seuil = 0x70u;

    START_SL = 0u;
    START_ROT = 0u;
    DIR_ROT = 0u;
    MOTOR_RIGHT = 0u;
    MOTOR_LEFT = seuil;

    while (1) {
        uint8_t vect = 0u;
        uint8_t pos_code = 0u;
        int pos_hw = 0;
        int pos_sw = 0;
        bool ready_ok = false;
        bool line_lost = false;
        bool coherent = false;

        ready_ok = trigger_and_wait_ready();
        if (!ready_ok) {
            LEDS_ADR = 0x80u;
            delay_cycles(200000u);
            continue;
        }

        DIR_ROT = 0u;
        vect = (uint8_t)(SW_ADR & 0x7Fu);

        DIR_ROT = 1u;
        pos_code = (uint8_t)(SW_ADR & 0x0Fu);
        DIR_ROT = 0u;

        pos_hw = (int)pos_code - 6;
        pos_sw = compute_position_from_vect(vect);
        line_lost = ((FIN_ROT & 0x1u) != 0u);

        coherent = (pos_hw == pos_sw) && (line_lost == (vect == 0u));

        if (coherent) {
            LEDS_ADR = (uint32_t)(vect & 0x7Fu);
        } else {
            LEDS_ADR = (uint32_t)(0x80u | (vect & 0x7Fu));
        }

        delay_cycles(250000u);
    }
}
