#include "cmp_regs.h"
#include "macros.h"

void cmp_enable(){
    SET_BIT(*CMP_CTRL, CMP_EN_BIT);
}

void cmp_disable(){
    CLR_BIT(*CMP_CTRL, CMP_EN_BIT);
}

void cmp_set_pinp(unsigned int src){
    
    unsigned int mask = 0xFFFFFFF9;
    unsigned int source = (src << 1);
     *CMP_CTRL &= mask;
    *CMP_CTRL |= source;
    //unsigned int ctrl = *CMP_CTRL;
    //ctrl &= mask;
    //ctrl |= source;
    //*CMP_CTRL = ctrl;
}

void cmp_set_ninp(unsigned int src){
    unsigned int mask = ~(3 << 3);
    unsigned int source = src << 3;
    //unsigned int ctrl = *CMP_CTRL;
    *CMP_CTRL &= mask;
    *CMP_CTRL |= source;
    
}

unsigned int cmp_status(){
    return (*CMP_OUT) & 1;
}

