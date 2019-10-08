#include "base_addr.h"
#include "macros.h"

#define     CLKCTRL_PLLCR_REG       0x00000000
#define     CLKCTRL_PLLTR_REG       0x00000004
#define     CLKCTRL_CLKCR_REG       0x00000008


unsigned int volatile * const CLKCTRL_PLLCR = (unsigned int *) (CLK_CTRL_BASE_ADDR_0 + CLKCTRL_PLLCR_REG);
unsigned int volatile * const CLKCTRL_PLLTR = (unsigned int *) (CLK_CTRL_BASE_ADDR_0 + CLKCTRL_PLLTR_REG);
unsigned int volatile * const CLKCTRL_CLKCR = (unsigned int *) (CLK_CTRL_BASE_ADDR_0 + CLKCTRL_CLKCR_REG);
