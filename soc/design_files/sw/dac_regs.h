#include "base_addr.h"
#include "macros.h"

#define     DAC_CTRL_REG        0x00000000
#define     DAC_DATA_REG        0x00000004

#define     DAC_SAMPLE_BIT          0x0
#define     DAC_SAMPLE_SIZE         0x8

#define     DAC_EN_BIT              0x0
#define     DAC_EN_SIZE             0x1

#define     DAC_VREFHSEL_BIT        0x1
#define     DAC_VREFHSEL_SIZE       0x1


unsigned int volatile * const DAC_CTRL = (unsigned int *) (DAC_BASE_ADDR_0 + DAC_CTRL_REG);
unsigned int volatile * const DAC_DATA = (unsigned int *) (DAC_BASE_ADDR_0 + DAC_DATA_REG);
