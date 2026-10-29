
#include "xil_io.h"
#include <stdint.h>

#define LED_BASE  0x44A00000U
#define LED_DATA  (LED_BASE + 0x00U)
#define LED_CTRL  (LED_BASE + 0x04U)

#define DELAY_COUNT  100U

volatile uint32_t test_result = 0;

static void delay_loop(void)
{
    volatile uint32_t i;

    for (i = 0; i < DELAY_COUNT; i++) {
        // Delay between LED test states
    }
}

int main(void)
{
    // Test 1: LED = 0101
    Xil_Out32(LED_DATA, 0x05U);
    Xil_Out32(LED_CTRL, 0x01U);

    if (Xil_In32(LED_DATA) != 0x05U)
        test_result |= 0x01U;

    delay_loop();

    // Test 2: LED = 1010
    Xil_Out32(LED_DATA, 0x0AU);

    if (Xil_In32(LED_DATA) != 0x0AU)
        test_result |= 0x02U;

    delay_loop();

    // Test 3: Disable LED
    Xil_Out32(LED_CTRL, 0x00U);

    if (Xil_In32(LED_CTRL) != 0x00U)
        test_result |= 0x04U;

    delay_loop();

    // Test 4: LED = 1111
    Xil_Out32(LED_DATA, 0x0FU);
    Xil_Out32(LED_CTRL, 0x01U);

    if (Xil_In32(LED_DATA) != 0x0FU)
        test_result |= 0x08U;

    if (Xil_In32(LED_CTRL) != 0x01U)
        test_result |= 0x10U;

    delay_loop();

    // Stay here so the testbench can check outputs
    while (1) {
    }

    return 0;
}
