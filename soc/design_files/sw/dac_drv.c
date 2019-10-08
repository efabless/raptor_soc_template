#include "dac_regs.h"
#include "macros.h"

void dac_enable(){
    SET_BIT(*DAC_CTRL, DAC_EN_BIT);
    //*DAC_CTRL = 1;
}

void dac_set_vrefh(unsigned int sel){
    unsigned int src = (sel&1) << 1;
    unsigned int mask = 0xFFFFFFFD;
    *DAC_CTRL &= mask;
    *DAC_CTRL |= src;
}

void dac_disable(){
    CLR_BIT(*DAC_CTRL, DAC_EN_BIT);
}

void dac_write(unsigned int sample){
    *DAC_DATA = sample;
}
