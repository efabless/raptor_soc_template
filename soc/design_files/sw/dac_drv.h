#define DAC_VREFH_EXT   0
#define DAC_VREFH_BG    1

void dac_enable();
void dac_disable();
void dac_set_vrefh(unsigned int sel);
void dac_write(unsigned int sample);
