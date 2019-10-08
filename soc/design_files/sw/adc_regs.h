#include "base_addr.h"
#include "macros.h"

#define     ADC_CTRL_REG        0x00000000
#define     ADC_DATA_REG        0x00000004
#define     ADC_STATUS_REG      0x00000008
#define     ADC_PRESCALE_REG    0x00000010

#define     ADC_SAMPLE_BIT          0x0
#define     ADC_SAMPLE_SIZE         0xA

#define     ADC_EN_BIT              0x0
#define     ADC_EN_SIZE             0x1
#define     ADC_START_BIT           0x1
#define     ADC_START_SIZE          0x1
#define     ADC_MUXSEL_BIT          0x2
#define     ADC_MUXSEL_SIZE         0x3
#define     ADC_VREFHSEL_BIT        0x5
#define     ADC_VREFHSEL_SIZE       0x1


#define     ADC_EOC_BIT              0x0
#define     ADC_EOC_SIZE             0x1

unsigned int volatile * const ADC_CTRL = (unsigned int *) (ADC_BASE_ADDR_0 + ADC_CTRL_REG);
unsigned int volatile * const ADC_DATA = (unsigned int *) (ADC_BASE_ADDR_0 + ADC_DATA_REG);
unsigned int volatile * const ADC_STATUS = (unsigned int *) (ADC_BASE_ADDR_0 + ADC_STATUS_REG);
unsigned int volatile * const ADC_PRESCALE = (unsigned int *) (ADC_BASE_ADDR_0 + ADC_PRESCALE_REG);
