#define ADC_VREFH_EXT   0
#define ADC_VREFH_BG    1

void adc_enable();
void adc_disable();
unsigned int adc_acquire();
void adc_set_prescalar(unsigned int);
void adc_set_channel(unsigned int);
void adc_set_vrefh(unsigned int);
