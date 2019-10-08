#include "dbgio_drv.h"
#include "adc_drv.h"
#include "dac_drv.h"
#include "bg_drv.h"
#include "gpio_drv.h"
#include "23lc512_drv.h"
#include "i2c_drv.h"
#include "tmr_drv.h"
#include "pwm_drv.h"
#include "cmp_drv.h"
#include "clkctrl_regs.h"

<%

let apbGPIOComps = [];
let ahbGPIOComps = [];

for (let addr in base_address) {
  if (base_address[addr].ip.category === 'APB GPIO') {
		apbGPIOComps.push(base_address[addr]);
	} else if (base_address[addr].ip.category === 'AHB GPIO') {
		ahbGPIOComps.push(base_address[addr]);
	}
}

var gpioSize = 16;
if (apbGPIOComps.length) {
	gpioSize = parseInt(apbGPIOComps[0].options.pin_size || 16);
} else if (ahbGPIOComps.length) {
	gpioSize = parseInt(ahbGPIOComps[0].options.pin_size || 16);
}

var magicIncrement = Math.floor(((1 << (gpioSize / 2)) - 1) / 2); //MUST MATCH WITH ONE IN SoC_tb
var gpioH = gpioSize / 2;

var gpioMask = (1 << gpioH) - 1;
var gpioPortSet = gpioMask << gpioH; // lsbs are 0, msbs are 1

%>

/*
  Test 10: a simple test to make sure that the SoC is out of reset
  Tests 20, 21, 22, 23, 24:  ADC/DAC?AMUX/VREFMUX (ADC-DAC Loopback)
  Test 30: GPIO
  Test 40: TMR test
  Test 50: PWM
  Tests 60, 61: COMP
  Test 70, 71, 72: CLKCTRL Tests 
  Test 80: SPI
  Test 90: I2C
  Tests A0, A1, A2: SRAM read/write of different sizes (8-bit, 16-bit and 32-bit)
  Test E0: Performance test (~163 cycles/iteration)
*/

void test_10();

void test_20();
void test_21();
void test_22();
void test_23();
void test_24();


void test_30();

void test_40 (); // Excluded

void test_50(); //

void test_60(); 
void test_61(); 


void test_70();
void test_71();
void test_72();
void test_80(); 

void test_90(); //

void test_A0();
void test_A1();
void test_A2();

void test_E0();

int comp_w_error(int x, int y, int e){
  int diff = x - y;
  //if(diff == 0) return 1;
  if(diff > e) return 0;
  if(diff < (-1*e)) return 0;
  return 1;
}

void dummy_delay(){
    int i;
    for(i=0; i<25; i++);
}


int main(){
#ifdef TEST_NAME
  TEST_NAME();
#else
  test_10();
#endif
}

// Simple test case
#if TEST == 0x10 || !defined(TEST_NAME)
void test_10(){
  dbgio_startTest(0x10, 0xFFF);
  dbgio_endTest(1);
}
#endif

// just a simple loopback - Default ANA channel (0) and default VREFH (0: External)
#if TEST == 0x20
void test_20(){
  dbgio_startTest(0x20, 0xFFF);
  dac_enable();
  adc_set_prescalar(19);  // adc_clk = clk/2*(19+1) = clk/40
  adc_enable();
  dac_write(25);
  int sample = adc_acquire();
  if(sample == 25) dbgio_endTest(1);
  else dbgio_endTest(0);
  while(1);
  //return 0;
}
#endif

// Loop back with an ascending ramp - Default ANA channel (0) and default VREFH (0: External)
#if TEST == 0x21
void test_21(){
  int i;
  int sample;
  dbgio_startTest(0x21, 0xFFF);
  dac_enable();
  adc_set_prescalar(19);  // adc_clk = clk/2*(19+1) = clk/40
  adc_enable();
  for(i=10; i<1000; i+=100) {
    dac_write(i);
    sample = adc_acquire();
    if(comp_w_error(sample, i, 10) == 0) break; // Break if Error is > 1%
  }
  //dbgio_setTestID(comp_w_error(sample, i, 2));
  if(i>=1000) 
    dbgio_endTest(1);
  else 
    dbgio_endTest(0);
  while(1);
  //return 0;
}
#endif

// Loopback with different Analog channels
#if TEST == 0x22
void test_22(){
  int sample;
  dbgio_startTest(0x22, 0xFFF);
  dac_enable();
  adc_set_prescalar(19);  // adc_clk = clk/2*(19+1) = clk/40
  adc_enable();
  dac_write(250);         // 0.5v for External VrefH of 2.046
  
  adc_set_channel(7);
  sample = adc_acquire();
  if(comp_w_error(sample, 250, 10) == 0) dbgio_endTest(0);
  
  adc_set_channel(1);
  sample = adc_acquire();
  if(comp_w_error(sample, 250, 10) == 0) dbgio_endTest(0);   // 0.5v = 250
  
  adc_set_channel(2);
  sample = adc_acquire();
  if(comp_w_error(sample, 500, 10) == 0) dbgio_endTest(0);   // 1.0v == 500
  
  adc_set_channel(5);
  sample = adc_acquire();
  if(comp_w_error(sample, 625, 10) == 0) dbgio_endTest(0);   // 1.25v == 625 
  
  adc_set_channel(0);
  sample = adc_acquire();
  if(comp_w_error(sample, 250, 10) == 0) dbgio_endTest(0);
  
  dbgio_endTest(1);

  while(1);
  //return 0;
}
#endif

// ADC VREFH Mux test (ADC-DAC loopback)
#if TEST == 0x23
void test_23(){
  int sample;
  dbgio_startTest(0x23, 0xFFF);
  dac_enable();
  adc_set_prescalar(19);  // adc_clk = clk/2*(19+1) = clk/40
  adc_enable();
  
  dac_write(375);     // 0.75v
  sample = adc_acquire();
  if(comp_w_error(sample, 375, 10) == 0) dbgio_endTest(0);
 
  // now change ADC VREF to the the internal 3.3V
  adc_set_vrefh(ADC_VREFH_BG);
  sample = adc_acquire();
  if(comp_w_error(sample, 232, 10) == 0) dbgio_endTest(0); // 375*2.046/3.3=232.5
 
  dbgio_endTest(1);
 
  while(1);
  //return 0;
}
#endif

// DAC VREFH Mux test (ADC-DAC loopback)
#if TEST == 0x24
void test_24(){
int sample;
  dbgio_startTest(0x24, 0xFFF);
  dac_enable();
  adc_set_prescalar(19);  // adc_clk = clk/2*(19+1) = clk/40
  adc_enable();
  
  dac_write(375);     // 0.75v
  sample = adc_acquire();
  if(comp_w_error(sample, 375, 10) == 0) dbgio_endTest(0);
 
  // now change ADC VREF to the the internal 3.3V
  dac_set_vrefh(ADC_VREFH_BG);
  sample = adc_acquire();
  if(comp_w_error(sample, 605, 10) == 0) dbgio_endTest(0); // 375 *3.3/2.046=605
 
  dbgio_endTest(1);
 
  while(1);
  //return 0;
}
#endif

// GPIO test
// The testbench adds <%=magicIncrement%> to the lower <%=gpioH%> bits and feeds the sum to the upper <%=gpioH%> bits
#if TEST == 0x30
void test_30(){
  int magic = 6;
  dbgio_startTest(0x30, 0xFFF);
  gpio_set_dir(<%=gpioPortSet%>);   // lower <%=gpioH%> pins are o/p and higher <%=gpioH%> pins are i/p
  gpio_write(magic);
  int data = gpio_read();
  if(((data>><%=gpioH%>) & <%=gpioMask%>) == (magic+<%=magicIncrement%>)) dbgio_endTest(1);
  dbgio_endTest(0);
  
  while(1);
  //return 0;
}

#endif

// Timer Basic Test
#if TEST == 0x40
void test_40(){
  dbgio_startTest(0x40, 0xFFF);

  tmr_disable();

  // Timer_clk = clk / (PRE+1)
  tmr_init(9, 99);  //  tmr clk freq = clk/(99+1)

  tmr_enable();
  
  while(tmr_getOVF() == 0);
  
  tmr_disable();

  dbgio_endTest(1);

  while(1);
}
#endif

// PWM Test
// This would produce 5 cycles of 75% ON PWM signal
#if TEST == 0x50
void test_50(){
  dbgio_startTest(0x50, 0xFFF);

  pwm_disable();

  // PWM period = (CMP1 + 1)/timer_clk = (CMP1 + 1)*(PRE + 1)/clk
	// PWM off cyle % = (CMP1 + 1)/(CMP2 + 1)
  pwm_init(199, 49, 9);   //  period = (199+1)/(clk/(9+1)) = 2000/clk, 
                          //  OFF % = 50/200 * 100 = 25%

  pwm_enable();

  //dummy delay
  for(int volatile i=0; i<500; i++);

  // flag a failed test if the TB verifier did not count 5 edges
  dbgio_endTest(0);

  while(1);

}
#endif

// Analog CMP Test
// +ve terminal connected to DAC
// -ve terminal connected to AN9 (1.3V)
#if TEST == 0x60
void test_60(){
  int dac = 465;
  int r;

  dbgio_startTest(0x60, 0xFFF);
  dac_set_vrefh(ADC_VREFH_BG);
  dac_enable();
  
  unsigned int * cmp_ctrl_addr = (unsigned int *) (0x40a00000 + 0x4);
  *cmp_ctrl_addr = 0x9;
  
  dac_write(dac);       // 1.5v = 465
  
  r = cmp_status();
  if(r != 1) dbgio_endTest(0); // 1.5 > 1.3

  dbgio_endTest(1);

  while(1);
}
#endif

#if TEST == 0x61
void test_61(){
  int r;
  dbgio_startTest(0x61, 0xFFF);
  dac_set_vrefh(ADC_VREFH_BG);
  dac_enable();

  unsigned int * cmp_ctrl_addr = (unsigned int *) (0x40a00000 + 0x4);
  *cmp_ctrl_addr = 0x9;
  dac_write(155);       // 1.5v = 155
  r = cmp_status();
  //dbgio_setTestID(r);
  if(r != 0) dbgio_endTest(0); // 0.5 < 1.3

  dbgio_endTest(1);

  while(1);
}
#endif

// CLKCTRL Tests
#define   HSE_ON      *CLKCTRL_CLKCR |= 0x10
#define   PLL_ON      *CLKCTRL_PLLCR |= 0x1
#define   PLL_DIV(d)  *CLKCTRL_PLLCR &= 0x3; *CLKCTRL_PLLCR |= (d<<2); *CLKCTRL_CLKCR |= 2

// switch from Internal Oscillator to external XTAL oscillator
#if TEST == 0x70
void test_70(){
  dbgio_startTest(0x70, 0xFFF);
  // turn on the XTAL Oscillator
  HSE_ON;
  dummy_delay;
  
  // configure the clock muxes
  *CLKCTRL_CLKCR |= 0x5;
  dummy_delay;

  dbgio_endTest(1);
}
#endif

// Configure the PLL (HSI, DIV4) then switch to the PLL
#if TEST == 0x71
void test_71(){
  dbgio_startTest(0x71, 0xFFF);
  
  // Select the XTAL OSC as the PLL source
  *CLKCTRL_PLLCR |= 0x2;

  // COnfigure the divsor and disable the DIV bypassing
  PLL_DIV(1); 
  
  // enable the PLL
  PLL_ON;
  dummy_delay;

  // PLL Bypassing is disabled by default
  // Select the PLL as a clock source
  *CLKCTRL_CLKCR |= 0x4;
  dummy_delay;

  dbgio_endTest(1);
}
#endif

// Configure the PLL (HSE, DIV8) then switch to the PLL
#if TEST == 0x72
void test_72(){
  dbgio_startTest(0x72, 0xFFF);
  
  // turn on the XTAL Oscillator
  HSE_ON;
  dummy_delay;

  // The default PLL source is the internal RCOSC
  // COnfigure the divsor and disable the DIV bypassing
  PLL_DIV(2); 
  
  // enable the PLL
  PLL_ON;
  dummy_delay;

  // PLL Bypassing is disabled by default
  // Select the PLL as a clock source
  *CLKCTRL_CLKCR |= 0x4;
  dummy_delay;

  dbgio_endTest(1);
}
#endif

// SPI
#if TEST == 0x80
void test_80(){
  int data;

  dbgio_startTest(0x80, 0xFFF);
  spi_configure(0,0,20);
  // some dummy delay
  for(int i=0;i<25;i++);
  write_byte(21, 55);
  data = read_byte(21);
  if(data == 55) dbgio_endTest(1);
  else dbgio_endTest(0);

  while(1);
  //return 0;
}
#endif

#if TEST == 0x90
void test_90(){
  dbgio_startTest(0x90, 0xFFF);


  // initialize the i2c master
  i2c_init(5);

  // send 69 to i2c device with address 6
  i2c_send(6, 69);

  for(int i=0; i<30; i++);
  dbgio_endTest(0);
  while(1);
}
#endif

//memory test
#if TEST == 0xA0
void test_A0(){
  int e;
  char c[10];
  short s[10];
  int i[10];

  dbgio_startTest(0xA0, 0xFFF);
   
  for(e=0; e<10; e++)
    c[e] = e;
  
  for(e=0; e<10; e++)
    if(e != c[e]) dbgio_endTest(0);
  
  dbgio_endTest(1);
}
#endif

#if TEST == 0xA1
void test_A1(){
  int e;
  char c[10];
  short s[10];
  int i[10];

  dbgio_startTest(0xA1, 0xFFF);
   
  for(e=0; e<10; e++)
    c[e] = e;
  
  for(e=0; e<10; e++)
    if(e != c[e]) dbgio_endTest(0);
  
  
  for(e=0; e<10; e++)
    s[e] = e*256 + e;
  
  for(e=0; e<10; e++)
    if((e*256 + e) != s[e]) dbgio_endTest(0);
 
  
  dbgio_endTest(1);
}
#endif

#if TEST == 0xA2
void test_A2(){
  int e;
  char c[10];
  short s[10];
  int i[10];

  dbgio_startTest(0xA2, 0xFFF);
   
  for(e=0; e<10; e++)
    c[e] = e;
  
  for(e=0; e<10; e++)
    if(e != c[e]) dbgio_endTest(0);
  
  
  for(e=0; e<10; e++)
    s[e] = e*256 + e;
  
  for(e=0; e<10; e++)
    if((e*256 + e) != s[e]) dbgio_endTest(0);
 
  for(e=0; e<10; e++)
    i[e] = e*256*256 + e*64 + e;
  
  for(e=0; e<10; e++)
    if((e*256*256 + e*64 + e) != i[e]) dbgio_endTest(0);

  dbgio_endTest(1);
}
#endif

unsigned char test_A3_fn(unsigned char x, unsigned char y){
  return x+y;
}

#if TEST == 0xA3
void test_A3(){
  dbgio_startTest(0xA2, 0xFFF);
  unsigned char volatile * const c_ptr = (unsigned char *) 0x20002001;
  *c_ptr = 10;

  int y = *c_ptr;
  if(y!=10) dbgio_endTest(0);
  /* 
  int r = test_A3_fn(10,20);
  if(r!=30) {
    dbgio_endTest(0);
  }
#endif*/
  dbgio_endTest(1);
}

#endif

// Performance Test
#if TEST == 0xE0
void test_E0(){
  int i;
  int sum = 0;
  int max = 500;

  dbgio_startTest(0xe0, 0xFFF);

  for(i=0; i<max; i++)
    sum += i;

  dbgio_endTest(1);
}
#endif