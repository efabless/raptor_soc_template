<% var reverseBaseAddress = {}
for (var addr in base_address) {
	reverseBaseAddress[base_address[addr].index] = base_address[addr]
}
var componentsMap = {}
for (var addr in base_address) {
	componentsMap[base_address[addr].ip.component.id] = base_address[addr]
}
var apbGPIOCount = 0;
var uartCount = 0;
var uartComps = [];
var ahbGPIOCount = 0;
var ahbGPIOComps = [];
var ahbSPICount = 0;
var ahbSPIComps = [];
var i2cCount = 0;
var pwmCount = 0;
var tmrCount = 0;
var apbSPICount = 0;
var cmpCount = 0;
var adcCount = 0;
var dacCount = 0;
var bgCount = 0;
var ahbClocks = [];

for (var addr in base_address) {
	if (base_address[addr].ip.category === 'APB GPIO') {
		apbGPIOCount++;
	} else if (base_address[addr].ip.category === 'APB UART') {
		uartCount++;
		uartComps.push(base_address[addr]);
	} else if (base_address[addr].ip.category === 'AHB Clock Control') {
		ahbClocks.push(base_address[addr]);
	} else if (base_address[addr].ip.category === 'AHB SPI') {
		ahbSPICount++;
		ahbSPIComps.push(base_address[addr]);
	} else if (base_address[addr].ip.category === 'AHB GPIO') {
		ahbGPIOCount++;
		ahbGPIOComps.push(base_address[addr]);
	} else if (base_address[addr].ip.category === 'APB i2c') {
		i2cCount++;
	} else if (base_address[addr].ip.category === 'APB Comparator') {
		cmpCount++;
	} else if (base_address[addr].ip.category === 'APB SPI') {
		apbSPICount++;
	} else if (base_address[addr].ip.category === 'APB PWM') {
		pwmCount++;
	} else if (base_address[addr].ip.category === 'APB Timer') {
		tmrCount++;
	} else if (base_address[addr].ip.category === 'APB Bandgap') {
		bgCount++;
	} else if (base_address[addr].ip.category === 'APB ADC') {
		adcCount++;
	} else if (base_address[addr].ip.category === 'APB DAC') {
		dacCount++;
	}
}

var is2Pow = ((mapped_count + 1) & mapped_count)? 0: 1;
var muxSelSize = Math.ceil(Math.log2(mapped_count + 1 + is2Pow));

let memoryIndex = null;
for (let i = 0; i < memory.length; i++) {
	if (memory[i].topModule === 'AHB2TWROM') {
		memoryIndex = componentsMap[memory[i].ip.component.id].index;
	}
}


let memSize = 8;
let memoryAddress = 0;
for (let addr in base_address) {
    if (base_address[addr].component === 'ahb2mem') {
        memoryAddress = addr;
        break;
    } 
}
if (base_address[memoryAddress]) {
	memSize = parseInt(base_address[memoryAddress].options.mem_size) || 8;
}
var isLarge = memSize > 32;
const bankSizeMap1 = {
	'8': ['2048', '2048', '2048', '2048'], // 8K
	'16': ['4096', '4096', '4096', '4096'], // 16K
	'32': ['8192', '8192', '8192', '8192'], // 32K
	'40': ['8192', '8192', '8192', '8192'], // 20K
	'48': ['8192', '8192', '8192', '8192'], // 24K
	'64': ['8192', '8192', '8192', '8192']  // 32K
};
const bankSizeMap2 = {
	'8': [0, 0, 0, 0], // 8K
	'16': [0, 0, 0, 0], // 16K
	'32': [0, 0, 0, 0], //32K
	'40': ['2048', '2048', '2048', '2048'], // 8K
	'48': ['4096', '4096', '4096', '4096'], // 16K
	'64': ['8192', '8192', '8192', '8192'] // 32K
};
// var AW = Math.ceil(Math.log2(4 * parseInt(bankSizeMap1[memSize][0])));
// if (isLarge) {
//  AW++;
// }
var AW = 11;
%>
`define DBG
`timescale 1ns/1ns
`define	JTAG

module DIGITALCORE(
	//CLOCKS & RESET
	output		wire				HCLK,
	input		wire				RESETn,

	// APB ADC and DAC Ports
	// ADC
	<% for (var i = 0; i < adcCount; i++) { %>
	output wire adc_clk_<%=i%>,
	output wire adc_en_<%=i%>,
	output wire adc_start_<%=i%>,
	input  wire adc_eoc_<%=i%>,
	output wire [2:0] adc_mux_sel_<%=i%>,
	input  wire [9:0] adc_data_<%=i%>,
	output  wire adc_vrefh_sel_<%=i%>,
	<% } %>

	<% for (var i = 0; i < dacCount; i++) { %>
	// DAC
	output wire [9:0] dac_data_<%=i%>,
	output wire dac_vrefh_sel_<%=i%>,
	output wire dac_en_<%=i%>,
	<% } %>


	// UART Ports
	<% for (var i = 0; i < uartCount; i++) { %>
	input wire RsRx_<%=i%>,
	output wire RsTx_<%=i%>,
	<% } %>
`ifdef DBG
	<%= ('output wire [31:0] DBGIO0,') %>
	<%= ('output wire TOUT0,')%>
`endif

	<% for (var i = 0; i < apbSPICount; i++) { %>
	input  wire APB_MSI_<%=i%>,
	output wire APB_MSO_<%=i%>,
	output wire APB_SSn_<%=i%>,
	output wire APB_SCLK_<%=i%>,
	<% } %>

	<% for (var i = 0; i < ahbSPICount; i++) { %>
	input  wire AHB_MSI_<%=i%>,
	output wire AHB_MSO_<%=i%>,
	output wire AHB_SSn_<%=i%>,
	output wire AHB_SCLK_<%=i%>,
	<% } %>

	<% for (var i = 0; i < pwmCount; i++) { %>
	output wire PWMO_<%=i%>,
	<% } %>
	<% for (var i = 0; i < bgCount; i++) { %>
	output wire bg_en_<%=i%>,
	<% } %>

	<% if (cmpCount) { %>
	<% for (var i = 0; i < cmpCount; i++) { %>
	input wire comp_out_<%=i%>,
	output wire comp_ena_<%=i%>,
	output wire [1:0]  comp_pinputsrc_<%=i%>,
	output wire [1:0]  comp_ninputsrc_<%=i%>,
	<% } %>
	<% } %>


	// APB GPIO Ports
	<% for (var i = 0; i < apbGPIOCount; i++) { %>
	input wire [15:0] APB_GPIOIN<%=i%>,
	output wire [15:0] APB_GPIOOUT<%=i%>,
	output wire [15:0] APB_GPIOPU<%=i%>,
	output wire [15:0] APB_GPIOPD<%=i%>,
	output wire [15:0] APB_GPIOEN<%=i%>,
	<% } %>

	<% for (var i = 0; i < ahbGPIOCount; i++) { %>
	input wire [15:0] AHB_GPIOIN<%=i%>,
	output wire [15:0] AHB_GPIOOUT<%=i%>,
	output wire [15:0] AHB_GPIOPU<%=i%>,
	output wire [15:0] AHB_GPIOPD<%=i%>,
	output wire [15:0] AHB_GPIOEN<%=i%>,
	<% } %>


	// APB i2c

	<% for (var i = 0; i < i2cCount; i++) { %>
	input wire scl_i_<%=i%>,	      // SCL-line input
	output wire scl_o_<%=i%>,	    // SCL-line output (always 1'b0)
	output wire scl_oen_o_<%=i%>,  // SCL-line output enable (active low)
	input wire sda_i_<%=i%>,       // SDA-line input
	output wire sda_o_<%=i%>,	    // SDA-line output (always 1'b0)
	output wire sda_oen_o_<%=i%>,  // SDA-line output enable (active low)

	<% } %>
	input   wire    [3:0]   fdi,        // data coming from the QPI flash
	output  wire    [3:0]   fdo,        // data going to the QPI flash
	output  wire    [3:0]   fdoe,       // o/p enable controls for the tri-state bufers
	output  wire            fsclk,      // flash clk
	output  wire            fcen,       // flash enable (active low)

	output wire				HRESETn,
	input wire [31:0]		HADDR,
	input wire [31:0]		HWDATA,
	input wire				HWRITE,
	input wire [1:0]		HTRANS,
	input wire [2:0]		HBURST,
	input wire				HMASTLOCK,
	input wire [3:0]		HPROT,
	input wire [2:0]		HSIZE,
	input wire				LOCKUP,
	output wire [31:0]		HRDATA,
	output wire				HRESP,
	output wire				HREADY,
	output wire [31:0]		IRQ,
	
	input wire RESET,           // SoC rst_lv
	input wire clk_hsi,       // SoC clk_hsi_lv
	input wire clk_hse,       // SoC clk_hse_lv
	input wire clk_pll_in,
	output wire clk_pll_out,
	output wire pll_cp_ena_lv,
	output wire pll_vco_ena_lv,
	output wire [3:0] pll_trim, //fixed
	output wire hsi_ena,
	output wire hse_ena,

`ifdef JTAG
	input   tms_pad_i,      // JTAG test mode select pad
	input   tck_pad_i,      // JTAG test clock pad
	input   trstn_pad_i,     // JTAG test reset pad
	input   tdi_pad_i,      // JTAG test data input pad
	output  tdo_pad_o,      // JTAG test data output pad
	output  tdo_padoe_o,

	output  sample_preload_select_o,
	output  tdi_o,
	input   bs_chain_tdo_i,
`endif

	input  wire   [31:0] SRAMRDATA,
	output wire    [31:0] WEn,
	output wire   [31:0] SRAMWDATA,
	output wire [<%=AW%>:0] SRAMADDR,  // SRAM address
	output wire          SRAMCS0,
	output wire          SRAMCS1,
	output wire          SRAMCS2,
	output wire          SRAMCS3
);


	wire 			TXEV;
	wire 			SLEEPING;

//SELECT SIGNALS
	wire [<%=muxSelSize - 1 %>: 0] MUX_SEL;

<% for (var addr in base_address) { %>
<%= ('	wire HSEL_S' + base_address[addr].index + ';') %>
<% } %>
	wire HSEL_S<%=mapped_count%>;
	wire HSEL_NOMAP;
	wire    [3:0] SRAMWEN;
	wire    [3:0] SRAMWEN_b;
	assign SRAMWEN = ~SRAMWEN_b;
	assign WEn = {
		SRAMWEN[3],
		SRAMWEN[3],
		SRAMWEN[3],
		SRAMWEN[3],
		SRAMWEN[3],
		SRAMWEN[3],
		SRAMWEN[3],
		SRAMWEN[3],

		SRAMWEN[2],
		SRAMWEN[2],
		SRAMWEN[2],
		SRAMWEN[2],
		SRAMWEN[2],
		SRAMWEN[2],
		SRAMWEN[2],
		SRAMWEN[2],

		SRAMWEN[1],
		SRAMWEN[1],
		SRAMWEN[1],
		SRAMWEN[1],
		SRAMWEN[1],
		SRAMWEN[1],
		SRAMWEN[1],
		SRAMWEN[1],

		SRAMWEN[0],
		SRAMWEN[0],
		SRAMWEN[0],
		SRAMWEN[0],
		SRAMWEN[0],
		SRAMWEN[0],
		SRAMWEN[0],
		SRAMWEN[0]
	};


	wire SRAMCS0_b;
	wire SRAMCS1_b;
	wire SRAMCS2_b;
	wire SRAMCS3_b;
	
	assign SRAMCS0 = ~SRAMCS0_b;
	assign SRAMCS1 = ~SRAMCS1_b;
	assign SRAMCS2 = ~SRAMCS2_b;
	assign SRAMCS3 = ~SRAMCS3_b;


//SLAVE READ DATA
<% for (var addr in base_address) { %>
<%= ('	wire HREADYOUT_S' + base_address[addr].index + ';') %>
<%= ('	wire [31: 0] HRDATA_S' + base_address[addr].index + ';') %>
<% } %>
	wire HREADYOUT_S<%=mapped_count%>;
	wire [31: 0] HRDATA_S<%=mapped_count%>;

	wire [31:0] PLLCR;
	wire [31:0] PLLTR;
	wire [31:0] CLKCR;
	wire [1:0] plldiv;  // from I/O Register
	wire  pllbypass;	// from I/O Register
	wire  pllsrc;	   // from I/O Register  
	wire  hsisel;	   // from I/O Register
	wire  divbypass;     // from I/O Register
	assign pll_cp_ena_lv = PLLCR[0];
	assign pllsrc = ~PLLCR[1];
	assign plldiv = PLLCR[3:2];
	assign pll_vco_ena_lv = PLLTR[0] | PLLCR[0];
	assign pll_trim = PLLTR[4: 1];
	assign pllbypass = ~CLKCR[0];
	assign divbypass = ~CLKCR[1];
	assign hsisel = CLKCR[2];
	assign hsi_ena = ~CLKCR[3];
	assign hse_ena = CLKCR[4];

	//assign HRESETn = RESETn;

	wire [3: 0] fdoe_bar;
	assign fdoe = ~fdoe_bar;

//SYSTEM GENERATES NO ERROR RESPONSE
	assign 			HRESP = 1'b0;

	wire isAddrLessEight = (HADDR[31: 0] < 8);
	wire HREADYOUT_ROM;
	wire HREADYOUT_SPI;
	wire [31: 0] HRDATA_ROM;
	wire [31: 0] HRDATA_SPI;
	wire ROM_SEL = HSEL_S<%=memoryIndex%> & isAddrLessEight;
	wire SPI_SEL = HSEL_S<%=memoryIndex%> & ~(isAddrLessEight);
	assign HRDATA_S<%=memoryIndex%> = ROM_SEL? HRDATA_ROM: HRDATA_SPI;
	assign HREADYOUT_S<%=memoryIndex%> = ROM_SEL? HREADYOUT_ROM: HREADYOUT_SPI;

//`define	SIMPLE_RESET_SYNC
`ifdef	SIMPLE_RESET_SYNC
	reg [1:0] rst_sync;
	always @ (posedge clk_hsi) begin
		rst_sync[0] <= RESETn;
		rst_sync[1] <= rst_sync[0];
	end
	assign HRESETn = rst_sync[0];
`else
	// Reset synchronizer based on Cummings Paper on Asynch Reset
	reg [2:0] rst_sync;
	always @ (posedge clk_hsi or negedge RESETn) begin
		if(!RESETn) begin
			rst_sync[0] <= 1'b0;
			rst_sync[1] <= 1'b0;	
			rst_sync[2] <= 1'b0;	
		end 
		else begin
			rst_sync[0] <= 1'b1;
			rst_sync[1] <= rst_sync[0];
			rst_sync[2] <= rst_sync[1];			
		end
	end
	assign HRESETn = rst_sync[2];

`endif


//AHBLITE SLAVE UART CONTROLLER

//CM0-DS INTERRUPT SIGNALS
<% var uartIRQMap = {}
var reverseUARTIRQMap = {}
var apbuartIndexMap = {}
uartComps.forEach(function(u, ind) {
apbuartIndexMap[u.ip.component.id] = ind
var irqStr = ((u.ip.component.options || {}).uart_irq || 'IRQ0')
var matches = /irq(\d+)/i.exec(irqStr) || []
var irqNo = parseInt(matches[1] || 0)
uartIRQMap[u.ip.component.id] = irqNo
reverseUARTIRQMap[irqNo] = u.ip.component.id
})%>
<% if (uartCount) { %>
	<%= uartComps.map((el, ind) => 'wire UART'+ ind + '_IRQ').join(';\n')%>;
	<% for (var id in uartIRQMap) { %>
	assign IRQ[<%= uartIRQMap[id] %>] = UART<%=apbuartIndexMap[id]%>_IRQ;
	<% } %>
<% }
for (var i = 0; i < 32; i++) {
	if (!reverseUARTIRQMap[i]) { %>
	assign IRQ[<%=i%>] = 0;
	<%}
} %>




//Address Decoder

	AHBDCD uAHBDCD (
		.HADDR(HADDR[31:0]),
		<% for (var i = 0; i < mapped_count; i++) { %>
			<% if (reverseBaseAddress[i])  {%>
		<%= ('.HSEL_S' + i + '(' + 'HSEL_S' + i + ')' + (',')) %>
			<% } else { %>
		<%= ('.HSEL_S' + i + '()' + (',')) %>
			<% } %>
		<% } %>
		.HSEL_S<%=mapped_count%>(HSEL_S<%=mapped_count%>),

		.HSEL_NOMAP(HSEL_NOMAP),
		.MUX_SEL(MUX_SEL[<%=muxSelSize - 1 %>: 0])
	);

//Slave to Master Mulitplexor

	AHBMUX uAHBMUX (
		.HCLK(HCLK),
		.HRESETn(HRESETn),
		.MUX_SEL(MUX_SEL[<%=muxSelSize - 1 %>: 0]),
		<% for (var i = 0; i < mapped_count; i++) { %>
			<% if (reverseBaseAddress[i])  {%>
		<%= ('.HRDATA_S' + i + '(' + 'HRDATA_S' + i + ')' + (',')) %>
			<% } else { %>
		<%= ('.HRDATA_S' + i + '()' + (',')) %>
			<% } %>
		<% } %>
		.HRDATA_NOMAP(32'hDEADBEEF),
		<% for (var i = 0; i < mapped_count; i++) { %>
			<% if (reverseBaseAddress[i])  {%>
		<%= ('.HREADYOUT_S' + i + '(' + 'HREADYOUT_S' + i + ')' + (',')) %>
			<% } else { %>
		<%= ('.HREADYOUT_S' + i + '()' + (',')) %>
			<% } %>
		<% } %>
		.HRDATA_S<%=mapped_count%>(HRDATA_S<%=mapped_count%>),
		.HREADYOUT_S<%=mapped_count%>(HREADYOUT_S<%=mapped_count%>),
		.HREADYOUT_NOMAP(1'b1),

		.HRDATA(HRDATA[31:0]),
		.HREADY(HREADY)
	);


	// AHBLite Peripherals
	<% ahbClocks.forEach(function(d, ind) { %>
	<%=`AHBCLKCTRL AHB_CLK${ind}(
		.HSEL(HSEL_S${componentsMap[d.ip.component.id].index}),
		.HCLK(HCLK),
		.HRESETn(HRESETn),
		.HREADY(HREADY),
		.HADDR(HADDR),
		.HTRANS(HTRANS[1:0]),
		.HWRITE(HWRITE),
		.HWDATA(HWDATA[31:0]),
		.HRDATA(HRDATA_S${componentsMap[d.ip.component.id].index}),
		.HREADYOUT(HREADYOUT_S${componentsMap[d.ip.component.id].index}),

		.PLLCR(PLLCR),
		.PLLTR(PLLTR),
		.CLKCR(CLKCR)
	);` %>
	<% }); %>
	clk_ctrl CLK_CTRL (
		.rst(RESET),	   // SoC rst_lv
		.clk_hsi(clk_hsi),	   // SoC clk_hsi_lv
		.clk_hse(~clk_hse),	   // SoC clk_hse_lv
		.clk_pll_in(clk_pll_in),	// pll_clk
		.clk(HCLK),	  // system master clock
		.clk_pll_out(clk_pll_out),  // SoC clk_pll_src
		.plldiv(plldiv),  // from I/O Register
		.pllbypass(pllbypass),	// from I/O Register
		.pllsrc(pllsrc),	   // from I/O Register  
		.hsisel(hsisel),	   // from I/O Register
		.divbypass(divbypass)	 // from I/O Register
	);

<% memory.forEach(function(m, ind) { %>
<% if (m.topModule === 'AHB2TWROM') { %>
	<%=`AHB2TWROM uAHB2ROM0 (
			//AHBLITE Signals
			.HSEL(ROM_SEL),
			.HCLK(HCLK),
			.HRESETn(HRESETn),
			.HREADY(HREADY),
			.HADDR(HADDR),
			.HTRANS(HTRANS[1:0]),
			.HWRITE(HWRITE),
			.HSIZE(HSIZE),
			.HWDATA(HWDATA[31:0]),
			.HRDATA(HRDATA_ROM),
			.HREADYOUT(HREADYOUT_ROM)
	);
	QSPIXIP uQSIXIP0 (
			.HCLK(HCLK),                        // System Clock
			.HRESETn(HRESETn),                       // System rest (active low)
			// flash interface
			.fdi(fdi),        // data coming from the QPI flash
			.fdo(fdo),        // data going to the QPI flash
			.fdoe(fdoe_bar),       // o/p enable controls for the tri-state bufers
			.fsclk(fsclk),      // flash clk
			.fcen(fcen),       // flash enable (active low)
			// AHB-Lite Slave Interface
			.HSEL(SPI_SEL),       // AHB peripheral select
			.HREADY(HREADY),
			.HTRANS(HTRANS[1:0]),
			.HSIZE(HSIZE),
			.HWRITE(HWRITE),
			.HADDR(HADDR),
			.HREADYOUT(HREADYOUT_SPI),
			.HRDATA(HRDATA_SPI)
	);`%>
<% } else { %>
		<%=`AHBSRAM uAHB2MEM0 (
			//AHBLITE Signals
			.HSEL(HSEL_S${componentsMap[m.ip.component.id].index}),
			.HCLK(HCLK),
			.HRESETn(HRESETn),
			.HREADY(HREADY),
			.HADDR(HADDR),
			.HTRANS(HTRANS[1:0]),
			.HWRITE(HWRITE),
			.HSIZE(HSIZE),
			.HWDATA(HWDATA[31:0]),
			.HRDATA(HRDATA_S${componentsMap[m.ip.component.id].index}),
			.HREADYOUT(HREADYOUT_S${componentsMap[m.ip.component.id].index}),
			
			.SRAMRDATA(SRAMRDATA), // SRAM Read Data
			.SRAMWEN(SRAMWEN_b),   // SRAM write enable (active high)
			.SRAMWDATA(SRAMWDATA), // SRAM write data
			.SRAMADDR(SRAMADDR),  // SRAM address
			.SRAMCS0(SRAMCS0_b),
			.SRAMCS1(SRAMCS1_b),
			.SRAMCS2(SRAMCS2_b),
			.SRAMCS3(SRAMCS3_b)
		);`%>
<% } %>

<% }) %>

	<%=`AHBDBGIO uAHBDBGIO0(
		.HSEL(HSEL_S${mapped_count}),
		.HCLK(HCLK),
		.HRESETn(HRESETn),
		.HREADY(HREADY),
		.HADDR(HADDR),
		.HTRANS(HTRANS[1:0]),
		.HWRITE(HWRITE),
		.HWDATA(HWDATA[31:0]),
		.HRDATA(HRDATA_S${mapped_count}),
		.HREADYOUT(HREADYOUT_S${mapped_count}),

		.GPIOOUT(DBGIO0),
		.T_OUT(TOUT0)
	);` %>

<% ahbuart.forEach(function(d, ind) { %>
	<%=`${d.topModule} uAHBUART${ind}(
		.HSEL(HSEL_S${componentsMap[d.ip.component.id].index}),
		.HCLK(HCLK),
		.HRESETn(HRESETn),
		.HREADY(HREADY),
		.HADDR(HADDR),
		.HTRANS(HTRANS[1:0]),
		.HWRITE(HWRITE),
		.HWDATA(HWDATA[31:0]),
		.HRDATA(HRDATA_S${componentsMap[d.ip.component.id].index}),
		.HREADYOUT(HREADYOUT_S${componentsMap[d.ip.component.id].index}),

		.RsRx(RsRx_${ind}),
		.RsTx(RsTx_${ind}),
		.uart_irq(UART${ind}_IRQ)
	);` %>
<% }) %>
<% ahbGPIOComps.forEach(function(d, ind) { %>
	<%=`${d.ip.topModule} uAHBGPIO${ind}(
		.HSEL(HSEL_S${componentsMap[d.ip.component.id].index}),
		.HCLK(HCLK),
		.HRESETn(HRESETn),
		.HREADY(HREADY),
		.HADDR(HADDR),
		.HTRANS(HTRANS[1:0]),
		.HWRITE(HWRITE),
		.HWDATA(HWDATA[31:0]),
		.HRDATA(HRDATA_S${componentsMap[d.ip.component.id].index}),
		.HREADYOUT(HREADYOUT_S${componentsMap[d.ip.component.id].index}),

		.GPIOIN(AHB_GPIOIN${ind}),
		.GPIOOUT(AHB_GPIOOUT${ind}),
		.GPIOPU(AHB_GPIOPU${ind}),
		.GPIOPD(AHB_GPIOPD${ind}),
		.GPIOEN(AHB_GPIOEN${ind})
	);` %>
<% }) %>
<% ahbSPIComps.forEach(function(d, ind) { %>
	<%=`${d.ip.topModule} uAHBSPI${ind}(
		.HSEL(HSEL_S${componentsMap[d.ip.component.id].index}),
		.HCLK(HCLK),
		.HRESETn(HRESETn),
		.HREADY(HREADY),
		.HADDR(HADDR),
		.HTRANS(HTRANS[1:0]),
		.HWRITE(HWRITE),
		.HWDATA(HWDATA[31:0]),
		.HRDATA(HRDATA_S${componentsMap[d.ip.component.id].index}),
		.HREADYOUT(HREADYOUT_S${componentsMap[d.ip.component.id].index}),

		.MSI(AHB_MSI_${ind}),
		.MSO(AHB_MSO_${ind}),
		.SSn(AHB_SSn_${ind}),
		.SCLK(AHB_SCLK_${ind})
	);` %>
<% }) %>
<% ahbbridges.forEach(function(d, ind) { %>
	<%=`${d.ip.component.component} uSYS${ind}(
		.HCLK(HCLK),
		.HRESETn(HRESETn),
		.HADDR(HADDR[31:0]),
		.HTRANS(HTRANS[1:0]),
		.HWDATA(HWDATA[31:0]),
		.HWRITE(HWRITE),
		.HREADY(HREADY),

		.HRDATA(HRDATA_S${componentsMap[d.ip.component.id].index}),
		.HREADYOUT(HREADYOUT_S${componentsMap[d.ip.component.id].index}),
		.HSEL(HSEL_S${componentsMap[d.ip.component.id].index}), `%>
	<% for (var i = 0; i < apbGPIOCount; i++) { %>
		.GPIOIN<%=i%>(APB_GPIOIN<%=i%>),
		.GPIOOUT<%=i%>(APB_GPIOOUT<%=i%>),
		.GPIOPU<%=i%>(APB_GPIOPU<%=i%>),
		.GPIOPD<%=i%>(APB_GPIOPD<%=i%>),
		.GPIOEN<%=i%>(APB_GPIOEN<%=i%>),
		<% } %>
		<% for (var i = 0; i < uartCount; i++) { %>
		.RsRx_<%=i%>(RsRx_<%=i%>),
		.RsTx_<%=i%>(RsTx_<%=i%>),
		.UART<%=i%>_IRQ(UART<%=i%>_IRQ),
	<% } %>
	<% for (var i = 0; i < apbSPICount; i++) { %>
		.MSI_<%=i%>(APB_MSI_<%=i%>),
		.MSO_<%=i%>(APB_MSO_<%=i%>),
		.SSn_<%=i%>(APB_SSn_<%=i%>),
		.SCLK_<%=i%>(APB_SCLK_<%=i%>),
	<% } %>

	<% for (var i = 0; i < pwmCount; i++) { %>
		.PWMO_<%=i%>(PWMO_<%=i%>),
	<% } %>
	<% for (var i = 0; i < bgCount; i++) { %>
		.bg_en_<%=i%>(bg_en_<%=i%>),
	<% } %>
	<% if (cmpCount) { %>
		<% for (var i = 0; i < cmpCount; i++) { %>
		.comp_out_<%=i%>(comp_out_<%=i%>),
		.comp_ena_<%=i%>(comp_ena_<%=i%>),
		.comp_pinputsrc_<%=i%>(comp_pinputsrc_<%=i%>),
		.comp_ninputsrc_<%=i%>(comp_ninputsrc_<%=i%>),
		<% } %>
	<% } %>
	<% if (i2cCount) { %>
		// APB i2c
		<% for (var i = 0; i < i2cCount; i++) { %>
		.scl_i_<%=i%>(scl_i_<%=i%>),	      // SCL-line input
		.scl_o_<%=i%>(scl_o_<%=i%>),	    // SCL-line output (always 1'b0)
		.scl_oen_o_<%=i%>(scl_oen_o_<%=i%>),  // SCL-line output enable (active low)
		.sda_i_<%=i%>(sda_i_<%=i%>),       // SDA-line input
		.sda_o_<%=i%>(sda_o_<%=i%>),	    // SDA-line output (always 1'b0)
		.sda_oen_o_<%=i%>(sda_oen_o_<%=i%>	),  // SDA-line output enable (active low)
		<% } %>
	<% } %>
	
	<% for (var i = 0; i < adcCount; i++) { %>

		// APB ADC and DAC Ports
		.adc_clk_<%=i%>(adc_clk_<%=i%>),
		.adc_en_<%=i%>(adc_en_<%=i%>),
		.adc_start_<%=i%>(adc_start_<%=i%>),
		.adc_eoc_<%=i%>(adc_eoc_<%=i%>),
		.adc_mux_sel_<%=i%>(adc_mux_sel_<%=i%>),
		.adc_vrefh_sel_<%=i%>(adc_vrefh_sel_<%=i%>),
		.adc_data_<%=i%>(adc_data_<%=i%>)<%=(i == adcCount - 1 && !dacCount)? '': ',' %>
<% } %>
	<% for (var i = 0; i < dacCount; i++) { %>
		.dac_data_<%=i%>(dac_data_<%=i%>),
		.dac_vrefh_sel_<%=i%>(dac_vrefh_sel_<%=i%>),
		.dac_en_<%=i%>(dac_en_<%=i%>)<%=i !== dacCount - 1? ',': ''%>
	<% } %>
	);
<% }) %>
`ifdef JTAG
	JTAG_TAP tap(
        // JTAG pads
        .tms_pad_i(tms_pad_i), 
        .tck_pad_i(tck_pad_i), 
		.trstn_pad_i(trstn_pad_i), 
		.tdi_pad_i(tdi_pad_i), 
		.tdo_pad_o(tdo_pad_o), 
		.tdo_padoe_o(tdo_padoe_o),

		// Select signals for boundary scan or mbist
		.extest_select_o(), 
		.sample_preload_select_o(sample_preload_select_o),
		.mbist_select_o(),
		.debug_select_o(),
		
		// TDO signal that is connected to TDI of sub-modules.
		.tdi_o(tdi_o), 
		
		// TDI signals from sub-modules
		.debug_tdo_i(),    // from debug module
		.bs_chain_tdo_i(bs_chain_tdo_i), // from Boundary Scan Chain
		.mbist_tdo_i()     // from Mbist Chain
    );
`endif
endmodule
