#define     CMP_INP_EXT   1
#define     CMP_INP_DAC   0


void cmp_enable();
void cmp_disable();
void cmp_set_pinp(unsigned int);
void cmp_set_ninp(unsigned int);
unsigned int cmp_status();