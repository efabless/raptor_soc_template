#ifndef NULL
    #define NULL 0
#endif
#define INVALID_ADDR NULL
<% var reverseBaseAddress = {} %>
<% for (var addr in base_address) { %>
	<% reverseBaseAddress[base_address[addr].index] = base_address[addr] %>
<% } %>
<% var componentsMap = {} %>
<% for (var addr in base_address) { %>
	<% componentsMap[base_address[addr].ip.component.id] = base_address[addr] %>
<% }
var i2cCount = 0;
var gpioCount = 0;
var ahbGPIOCount = 0;
var adcCount = 0;
var dacCount = 0;
var bridgeCount = 0;
var uartCount = 0;
var clkCount = 0;
var spiCount = 0;
var ahbSPICount = 0;
var pwmCount = 0;
var tmrCount = 0;
var cmpCount = 0;
var bgCount = 0;
var clkCtrlCount = 0;

for (var origAddr in base_address) {
	var category = base_address[origAddr].ip.category;
	addr = parseInt(origAddr, 10) << 16;
	let hexAddress = (addr >>> 0).toString(16);
	if (category === 'APB i2c') { %>
#define     I2C_BASE_ADDR_<%=i2cCount++%>       0x<%='0'.repeat(Math.max(8 - hexAddress.length, 0)) + hexAddress%>
	<% } else if (category === 'APB GPIO') { %>
#define     APB_GPIO_BASE_ADDR_<%=gpioCount++%>      0x<%='0'.repeat(Math.max(8 - hexAddress.length, 0)) + hexAddress%>
	<% } else if (category === 'AHB GPIO') {%>
#define     AHB_GPIO_BASE_ADDR_<%=ahbGPIOCount++%>      0x<%='0'.repeat(Math.max(8 - hexAddress.length, 0)) + hexAddress%>
	<% } else if (category === 'APB ADC') { %>
#define     ADC_BASE_ADDR_<%=adcCount++%>       0x<%='0'.repeat(Math.max(8 - hexAddress.length, 0)) + hexAddress%>
	<% } else if (category === 'APB DAC') { %>
#define     DAC_BASE_ADDR_<%=dacCount++%>       0x<%='0'.repeat(Math.max(8 - hexAddress.length, 0)) + hexAddress%>
	<% } else if (category === 'AHB Bridges') { %>
#define     APB_BASE_ADDR_<%=bridgeCount++%>       0x<%='0'.repeat(Math.max(8 - hexAddress.length, 0)) + hexAddress%>
	<% } else if (category === 'APB UART') { %>
#define     UART_BASE_ADDR_<%=uartCount++%>       0x<%='0'.repeat(Math.max(8 - hexAddress.length, 0)) + hexAddress%>
	<% } else if (category === 'APB Comparator') { %>
#define     COMPARATOR_BASE_ADDR_<%=cmpCount++%>     0x<%='0'.repeat(Math.max(8 - hexAddress.length, 0)) + hexAddress%>
	<% } else if (category === 'APB Timer') { %>
#define     TIMER_BASE_ADDR_<%=tmrCount++%>       0x<%='0'.repeat(Math.max(8 - hexAddress.length, 0)) + hexAddress%>
	<% } else if (category === 'APB SPI') { %>
#define     APB_SPI_BASE_ADDR_<%=spiCount++%>       0x<%='0'.repeat(Math.max(8 - hexAddress.length, 0)) + hexAddress%>
	<% } else if (category === 'AHB SPI') { %>
#define     AHB_SPI_BASE_ADDR_<%=spiCount++%>       0x<%='0'.repeat(Math.max(8 - hexAddress.length, 0)) + hexAddress%>
	<% } else if (category === 'APB Bandgap') { %>
#define     BG_BASE_ADDR_<%=bgCount++%>       0x<%='0'.repeat(Math.max(8 - hexAddress.length, 0)) + hexAddress%>
	<% } else if (category === 'APB PWM') { %>
#define     PWM_BASE_ADDR_<%=pwmCount++%>       0x<%='0'.repeat(Math.max(8 - hexAddress.length, 0)) + hexAddress%>
	<% } else if (category === 'AHB Clock Control') { %>
#define     CLK_CTRL_BASE_ADDR_<%=clkCtrlCount++%>       0x<%='0'.repeat(Math.max(8 - hexAddress.length, 0)) + hexAddress%>
	<% }
} %>
<% if (!ahbGPIOCount) { %>
#define     AHB_GPIO_BASE_ADDR_0		INVALID_ADDR
<% } %>
<% if (!gpioCount) { %>
#define     APB_GPIO_BASE_ADDR_0		INVALID_ADDR
<% } %>
<% if (!i2cCount) { %>
#define     I2C_BASE_ADDR_0      		INVALID_ADDR
<% } %>
<% if (!adcCount) { %>
#define     ADC_BASE_ADDR_0      		INVALID_ADDR
<% } %>
<% if (!dacCount) { %>
#define     DAC_BASE_ADDR_0      		INVALID_ADDR
<% } %>
<% if (!bridgeCount) { %>
#define     APB_BASE_ADDR_0      		INVALID_ADDR
<% } %>
<% if (!uartCount) { %>
#define     UART_BASE_ADDR_0      		INVALID_ADDR
<% } %>
<% if (!cmpCount) { %>
#define     COMPARATOR_BASE_ADDR_0      INVALID_ADDR
<% } %>
<% if (!tmrCount) { %>
#define     TIMER_BASE_ADDR_0      		INVALID_ADDR
<% } %>
<% if (!spiCount) { %>
#define     APB_SPI_BASE_ADDR_0			INVALID_ADDR
<% } %>
<% if (!pwmCount) { %>
#define     PWM_BASE_ADDR_0				INVALID_ADDR
<% } %>
<% if (!bgCount) { %>
#define     BG_BASE_ADDR_0				INVALID_ADDR
<% } %>
<% if (!clkCtrlCount) { %>
#define     CLK_CTRL_BASE_ADDR_0		INVALID_ADDR
<% } %>

<%=`#define     DBGIO_BASE_ADDR_0     0x24000000`%>
