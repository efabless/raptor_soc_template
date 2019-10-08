#include "macros.h"
#include "base_addr.h"
#include "bg_drv.h"


#define     BG_CTRL_REG        0x00000000

#define     BG_EN_BIT              0x0
#define     BG_EN_SIZE             0x1

unsigned int volatile * const BG_CTRL = (unsigned int *) (BG_BASE_ADDR_0 + BG_CTRL_REG);

void bg_enable(){
    SET_BIT(*BG_CTRL, BG_EN_BIT);
}

void bg_disable(){
    CLR_BIT(*BG_CTRL, BG_EN_BIT);
}