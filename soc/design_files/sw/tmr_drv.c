#include "tmr_drv.h"
#include "tmr_regs.h"


// Timer_clk = clk / (PRE+1)
void tmr_init(unsigned int cmp, unsigned int pre){
  *TMR_CMP = cmp;
  *TMR_PRE = pre;
}

void tmr_enable(){
  SET_BIT(*TMR_CTRL, TMR_EN_BIT);
}

void tmr_disable(){
  CLR_BIT(*TMR_CTRL, TMR_EN_BIT);
}

void tmr_clearOVF(){
  SET_BIT(*TMR_CTRL, TMR_OVCLR_BIT);
  CLR_BIT(*TMR_CTRL, TMR_OVCLR_BIT);
}

unsigned int tmr_getOVF(){
  return *TMR_STATUS;
}
