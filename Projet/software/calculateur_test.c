#include <stdint.h>

#define FIN_ROT       (*(volatile uint32_t *)0x04003000u) /* fin_rot_pio.s1  */
#define FIN_SL        (*(volatile uint32_t *)0x04003010u) /* fin_sl_pio.s1   */
#define DIR_ROT       (*(volatile uint32_t *)0x04003020u) /* dir_rot_pio.s1  */
#define START_ROT     (*(volatile uint32_t *)0x04003030u) /* start_rot_pio.s1*/
#define START_SL      (*(volatile uint32_t *)0x04003040u) /* start_sl_pio.s1 */
#define WRITEDATA_R   (*(volatile uint32_t *)0x04003050u) /* MOTOR_RIGHT.s1  */
#define WRITEDATA_L   (*(volatile uint32_t *)0x04003060u) /* MOTOR_LEFT.s1   */
#define LEDS_ADR      (*(volatile uint32_t *)0x04003070u) /* LED.s1          */
#define SWITCH_ADR    (*(volatile uint32_t *)0x04003080u) /* SW.s1           */

void delay(volatile int count)
{
	while (count--);
}

uint8_t read_page(uint8_t page)
{
	START_ROT = (uint32_t)((page >> 1) & 0x1u);
	DIR_ROT = (uint32_t)(page & 0x1u);
	delay(32);
	return (uint8_t)(SWITCH_ADR & 0xFFu);
}

int main(void)
{
	uint8_t op = 0u;
	uint8_t result_lo = 0u;
	uint8_t result_hi = 0u;
	uint8_t data_ir = 0u;
	uint8_t data_jr = 0u;
	uint16_t result_hw = 0u;
	uint16_t result_sw = 0u;
	uint32_t timeout = 0u;

	WRITEDATA_R = 0u;
	START_SL = 0u;
	START_ROT = 0u;
	DIR_ROT = 0u;

	while (1)
	{
		for (op = 0u; op < 4u; op++)
		{
			WRITEDATA_L = ((uint32_t)(op & 0x3u) << 8);

			START_SL = 1u;
			timeout = 300000u;
			while (((FIN_SL & 0x1u) == 0u) && (timeout > 0u))
			{
				timeout--;
			}
			START_SL = 0u;

			if (timeout == 0u)
			{
				LEDS_ADR = 0x80u;
				delay(200000);
				continue;
			}

			result_lo = read_page(0u);
			result_hi = read_page(1u);
			data_ir = read_page(2u);
			data_jr = read_page(3u);

			result_hw = (uint16_t)(((uint16_t)result_hi << 8) | (uint16_t)result_lo);

			if (op == 0u) {
				result_sw = (uint16_t)((uint16_t)data_ir + (uint16_t)data_jr);
			} else if (op == 1u) {
				result_sw = (uint16_t)((uint16_t)data_ir - (uint16_t)data_jr);
			} else if (op == 2u) {
				result_sw = (uint16_t)((uint16_t)data_ir << 1);
			} else {
				result_sw = (uint16_t)((uint16_t)data_ir >> 1);
			}

			if ((result_hw == result_sw) && ((FIN_ROT & 0x1u) == 0u))
			{
				LEDS_ADR = (uint32_t)(result_lo & 0xFFu);
			}
			else
			{
				LEDS_ADR = (uint32_t)(0x80u | (op << 4) | (result_lo & 0x0Fu));
			}

			delay(250000);
		}
	}
}
