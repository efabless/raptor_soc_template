#include "base_addr.h"


#define     CMP_CTRL_REG       0x00000004
#define     CMP_OUT_REG        0x00000000

#define     CMP_EN_BIT              0x0
#define     CMP_EN_SIZE             0x1

#define     CMP_PSRC_BIT          0x1
#define     CMP_PSRC_SIZE          0x1

#define     CMP_NSRC_BIT          0x2
#define     CMP_NSRC_SIZE          0x1



#define     CMP_OUT_BIT              0x0
#define     CMP_OUT_SIZE             0x1




unsigned int volatile * const CMP_CTRL = (unsigned int *) (COMPARATOR_BASE_ADDR_0 + CMP_CTRL_REG);
unsigned int volatile * const CMP_OUT = (unsigned int *) (COMPARATOR_BASE_ADDR_0 + CMP_OUT_REG);

