#include "adc_regs.h"
#include "macros.h"
#include "adc_drv.h"

void adc_enable(){
    SET_BIT(*ADC_CTRL, ADC_EN_BIT);
}

void adc_disable(){
    CLR_BIT(*ADC_CTRL, ADC_EN_BIT);
}

void adc_set_prescalar(unsigned int prescalar){
  *ADC_PRESCALE = prescalar;
}

void adc_set_channel(unsigned int ch){
    unsigned int channel = (ch&7) << 2;
    unsigned int mask = 0xFFFFFFE3;
    *ADC_CTRL &= mask;
    *ADC_CTRL |= channel;
}

void adc_set_vrefh(unsigned int sel){
    unsigned int src = (sel&1) << 5;
    unsigned int mask = 0xFFFFFFBF;
    *ADC_CTRL &= mask;
    *ADC_CTRL |= src;
}

unsigned int adc_acquire(){
    CLR_BIT(*ADC_CTRL, ADC_START_BIT);
    SET_BIT(*ADC_CTRL, ADC_START_BIT);
    // wait for EOC to go down first
    while( CHK_BIT (*ADC_STATUS, ADC_EOC_BIT) == 1 );
    while( CHK_BIT (*ADC_STATUS, ADC_EOC_BIT) == 0 );
    return (*ADC_DATA);
}
