<% var reverseBaseAddress = {}
for (var addr in base_address) {
	reverseBaseAddress[base_address[addr].index] = base_address[addr]
}
var componentsMap = {}
for (var addr in base_address) {
	componentsMap[base_address[addr].ip.component.id] = base_address[addr]
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
	// AW++;
// }
var AW = 11;
var memBlockCount = 1;
if (memSize >= 32) {
	memBlockCount = 2;
}
if (memSize >= 48) {
	memBlockCount = 3;
}
if (memSize >= 64) {
	memBlockCount = 4;
}
%>
<%
var apbGPIOCount = 0;
var apbGPIOComps = [];
var uartComps = [];
var dacComps = [];
var adcComps = [];
var i2cComps = [];
var tmrComps = [];
var tmrCount = 0;
var apbSPIComps = [];
var apbSPICount = 0;
var cmpComps = [];
var cmpCount = 0;
var pwmComps = [];
var pwmCount = 0;
var bgComps = [];
var bgCount = 0;
var ahbGPIOCount = 0;
var ahbGPIOComps = [];
var ahbSPICount = 0;
var ahbSPIComps = [];


for (var addr in base_address) {
	var category = base_address[addr].ip.category;
	base_address[addr].options = base_address[addr].options || {};
	if (category === 'APB GPIO') {
		apbGPIOCount++;
		apbGPIOComps.push(base_address[addr]);
	} else if (category === 'APB DAC') {
		dacComps.push(base_address[addr]);
		base_address[addr].options.io_dac_out = base_address[addr].options.io_dac_out || 'None';
	} else if (category === 'APB ADC') {
		adcComps.push(base_address[addr]);
		base_address[addr].options.io_adc_vin = base_address[addr].options.io_adc_vin || 'None';
	} else if (category === 'APB i2c') {
		i2cComps.push(base_address[addr]);
		base_address[addr].options.io_i2c_scl = base_address[addr].options.io_i2c_scl || 'None';
		base_address[addr].options.io_i2c_sda = base_address[addr].options.io_i2c_sda || 'None';
	} else if (category === 'APB UART') {
		uartComps.push(base_address[addr]);
		base_address[addr].options.io_uart_tx = base_address[addr].options.io_uart_tx || 'None';
		base_address[addr].options.io_uart_rx = base_address[addr].options.io_uart_rx || 'None';
	} else if (category === 'APB Timer') {
		tmrComps.push(base_address[addr]);
		tmrCount++;
		// base_address[addr].options.io_uart_tx = base_address[addr].options.io_uart_tx || 'None';
	} else if (category === 'APB Comparator') {
		cmpComps.push(base_address[addr]);
		cmpCount++;
		// base_address[addr].options.io_uart_tx = base_address[addr].options.io_uart_tx || 'None';
	} else if (category === 'APB Bandgap') {
		bgComps.push(base_address[addr]);
		bgCount++;
		//base_address[addr].options.io_uart_tx = base_address[addr].options.io_uart_tx || 'None';
	} else if (category === 'APB PWM') {
		pwmComps.push(base_address[addr]);
		pwmCount++;
	} else if (category === 'APB SPI') {
		apbSPIComps.push(base_address[addr]);
		apbSPICount++;
	} else if (category === 'AHB GPIO') {
		ahbGPIOComps.push(base_address[addr]);
		ahbGPIOCount++;
	} else if (category === 'AHB SPI') {
		ahbSPIComps.push(base_address[addr]);
		ahbSPICount++;
	}
}

let demoMode = adcComps.reduce(
	(result, current)=> result && current.options.raptor_demo === "Yes",
	true
);
let ANCount = cmpCount * 2 + 4 + adcComps.length * 4;

let doJTAGPortShare = true;
/*
	if (uartComps.length >= 2 && apbSPICount > 1) {
		let try0 = base_address[uartComps[0]].options.try_jtag_port_share;
		let try1 = base_address[uartComps[1]].options.try_jtag_port_share;
		let try2 = base_address[apbSPIComps[0]].options.try_jtag_port_share;
		doJTAGPortShare = try0 && try1 && try2;
	}
*/

%>
`timescale 1ns/1ns

`define JTAG

`ifndef GL
	`define RTL
`endif

module <%=top%> (
	input wire real VDD3V3,
	input wire real VDD1V8,
	input wire real VSS,

`ifdef JTAG
	<% if (!doJTAGPortShare) { %>
	input tms_pad,
	input tck_pad,
	input trstn_pad,
	input tdi_pad,
	output tdo_pad,
	output tdo_padoe,
	<% } else { %>
	input jtag_en,
	<% } %>
`endif
	
`ifdef DBG
	<%= ('output wire [31:0] DBGIO0,') %>
	<%= ('output wire TOUT0,')%>
`endif

	// UART
	<%
		let uartCompsStart = 0;
		if (doJTAGPortShare) {
			uartCompsStart = 2;
	%>
	input wire tms__RsRx_0,	
	output wire tdo__RsTx_0,

	input wire tdi__RsRx_1,
	output wire RsTx_1,
	<%	} %>

	<% for (var i = uartCompsStart; i < uartComps.length; i++) { %>
	input wire RsRx_<%=i%>,
	output wire RsTx_<%=i%>,
	<% } %>
	
	// AHB GPIO Ports
	<% for (var i = 0; i < ahbGPIOComps.length; i++) { %>
	inout wire [<%= parseInt(ahbGPIOComps[i].options.pin_size || 16) - 1 %>:0] AHB_GPIO<%=i%>,
	<% } %>
	// APB GPIO Ports
	<% for (var i = 0; i < apbGPIOComps.length; i++) { %>
	inout wire [<%= parseInt(apbGPIOComps[i].options.pin_size || 16) - 1 %>:0] APB_GPIO<%=i%>,
	<% } %>

	// External Clock Oscillator
	input wire real XI,
	output wire real XO,

	// SPI
	<%
		let apbSPIStart = 0;
		if (doJTAGPortShare) {
			apbSPIStart = 1;
	%>
	input  wire tck__APB_SPI_MSI_0,
	output wire APB_SPI_MSO_0,
	output wire APB_SPI_SSn_0,
	output wire APB_SPI_SCLK_0,
	<%	} %>
	<% for (var i = apbSPIStart; i < apbSPICount; i++) { %>
	input  wire APB_SPI_MSI_<%=i%>,
	output wire APB_SPI_MSO_<%=i%>,
	output wire APB_SPI_SSn_<%=i%>,
	output wire APB_SPI_SCLK_<%=i%>,
	<% } %>
	<% for (var i = 0; i < ahbSPICount; i++) { %>
	input  wire AHB_SPI_MSI_<%=i%>,
	output wire AHB_SPI_MSO_<%=i%>,
	output wire AHB_SPI_SSn_<%=i%>,
	output wire AHB_SPI_SCLK_<%=i%>,
	<% } %>

	// PWM
	<% for (var i = 0; i < pwmCount; i++) { %>
	output wire PWMO_<%=i%>,
	<% } %>
	
	// APB i2c
	<% for (var i = 0; i < i2cComps.length; i++) { %>
	inout wire i2c_cl_<%=i%>,
	inout wire i2c_da_<%=i%>,
	<% } %>

	inout wire [3:0] qspi_io,
	output wire qspi_sclk,
	output wire qspi_ce,
	

	// APB ADC and DAC Ports
	<% for (let i = 0; i < ANCount && demoMode; i++) { %>
	input wire real AN<%=i%>,
	<% } %>
	<%
	for (let i = 0; i < adcComps.length && !demoMode; i++) {
		for (let j = 0; j < 8; j++) {
	%>
	input wire real ADC_<%=i%>_AN<%=j%>,
	<% 	
		}
	}
	%>

	<% for (let i = 0; i < dacComps.length; i++) { %>
	output wire real OUT<%=i%>,
	<% } %>

	input wire real VREFL,
	input wire real VREFH
);
	wire real VDD1V8;
	wire dground;
	wire dpower;
	wire dpower_1v8;

	wire real bias10u, bias5u;
	wire rst, rstn;
	wire clk_hsi, clk_hse;

	wire [3:0] fdi;        // data coming from the QPI flash
	wire [3:0] fdo;        // data going to the QPI flash
	wire [3:0] fdoe;       // o/p enable controls for the tri-state bufers
	wire fsclk;      // flash clk
	wire fcen;       // flash enable (active low)

	wire [31:0] DBGIO0;
	wire TOUT0;


	<% for (var i = 0; i < apbSPICount; i++) { %>
	wire APB_MSI_<%=i%>;
	wire APB_MSO_<%=i%>;
	wire APB_SSn_<%=i%>;
	wire APB_SCLK_<%=i%>;
	<% } %>

	<% for (var i = 0; i < bgCount; i++) { %>
	wire bg_en_<%=i%>;
	<% } %>

	
	// These are coming/going from/to the digital core
	wire clk_pll;            
 	wire clk_pll_out;	 
 	wire [3:0] pll_trim;     
 	wire pll_vco_ena_lv;     
 	wire pll_cp_ena_lv;      

	wire hsi_ena;            // from DC;
	wire hse_ena;            // from DC
	wire rst_lv;             // to DC
	wire rstn_lv;

	wire clk_hse_lv;   // to DC
	wire HCLK;
	
	wire [31:0] SRAMRDATA; // SRAM Read Data
	wire [31:0] WEn;   // SRAM write enable (active high)
	wire [31:0] SRAMWDATA; // SRAM write data
	
	wire [<%=AW%>:0] SRAMADDR;  // SRAM address

	wire SRAMCS0;



	wire HRESETn;
	wire [31:0] HADDR;
	wire [31:0] HWDATA;
	
	wire HWRITE;
	wire [1:0] HTRANS; 
	wire [2:0] HBURST; 
	wire HMASTLOCK; 
	wire [3:0] HPROT; 
	wire [2:0] HSIZE; 
	wire LOCKUP; 
	wire [31:0] HRDATA; 
	wire HRESP; 
	wire HREADY; 
	wire [31:0] IRQ;

	<% for (let i = 0; i < cmpCount; i++) { %>
	// APB Comparator Analog nets
	wire comp_ena_<%=i%>;
	wire real comp_ninput_<%=i%>;
	wire real comp_pinput_<%=i%>;
	wire real bias400n_<%=i%>;

	wire adc_clk_<%=i%>;

	wire real dac_vrefh_<%=i%>;
	wire real adc_vrefh_<%=i%>;

	wire real dac_out_<%=i%>;


	wire comp_out_lv_<%=i%>;

	// APB Comparator 1.8V digital nets
	wire comp_ena;
	wire [1:0] comp_ninputsrc_<%=i%>;
	wire [1:0] comp_pinputsrc_<%=i%>;

	// APB Comparator 3.3V digital nets
	wire comp_ena_3v_<%=i%>;
	wire comp_out_<%=i%>;
	<% } %>

	<% if (doJTAGPortShare) { %>
	// TAP I/O mux o/p
	wire tdo_tx0_mux_o;
	<% } %>

	LOGIC0_3V ground_digital (
	`ifdef LVS
		 .gnd(VSS),
		 .vdd3(VDD3V3),
	`endif
		 .Q(dground)
	);
	
	LOGIC1_3V power_digital [1:0] (
`ifdef LVS
		.gnd(VSS),
		.vdd3(VDD3V3),
`endif
		.Q(dpower)
	);

	LOGIC1 power_digital_1v8_1 [1:0] (
`ifdef LVS
		.gnd(VSS),
		.vdd(VDD1V8),
`endif
		.Q(dpower_1v8)
	);

	CORNERESDF pf_corners [3:0] (
		.GNDO(VSS),
		.GNDR(VSS),
		.VDD(VDD1V8),
		.VDDO(VDD3V3),
		.VDDR(VDD3V3)
	);

	/* 8x clock multiplier PLL (NOTE: IP from A_CELLS_1V8) */
	apllc03_1v8 pll (
		 .VSSD(VSS),
		 .EN_VCO(pll_vco_ena_lv),
		 .EN_CP(pll_cp_ena_lv),
		 .B_VCO(bias5u),
		 .B_CP(bias10u),
		 .VSSA(VSS),
		 .VDDD(VDD1V8),
		 .VDDA(VDD1V8),
		 .VCO_IN(),
		 .CLK(clk_pll),		    // output (fast) clock
		 .REF(clk_pll_out),	    // input (slow) clock
		 .B(pll_trim) 	        // 4-bit trim
	);

	/* Biasing for PLL */
	acsoc04_1v8 pll_bias (
		 .EN(dpower_1v8),
		 .VDDA(VDD1V8),
		 .VSSA(VSS),
		 .CS3_8u(bias10u),
		 .CS2_4u(bias5u),
		 .CS1_2u(bias10u),
		 .CS0_1u(bias5u)
	);

	/* Level shift up */
	arcoc07_1v8 rcosc (
		.EN(dpower_1v8), // always enabled
		.OUT(clk_hsi),
		.VDDA(VDD1V8),
		.VSSA(VSS)
	);


	/* Crystal oscillator (5-12.5 MHz) (HSE) */
	wire xtal_ena_3v;
	LS_3VX2 xtal_ena_level (
		.VDD3V3(VDD3V3),
		.VDD1V8(VDD1V8),
		.VSSA(VSS),
		.A(hse_ena),
		.Q(xtal_ena_3v)
	);

	axtoc02_3v3 xtal (
		 .CLK(clk_hse),
		 .XI(XI),
		 .XO(XO),
		 .EN(xtal_ena_3v),
		 .GNDO(VSS),
		 .GNDR(VSS),
		 .VDD(VDD1V8),
		 .VDDO(VDD3V3),
		 .VDDR(VDD3V3)
	);

	BU_3VX2 xtal_out_level (
`ifdef LVS
		 .gnd(VSS),
		 .vdd3(VDD1V8),
`endif
		 .A(clk_hse),
		 .Q(clk_hse_lv)
	);

	/* 2 x 1.8V LDO REG */
	aregc01_3v3 regulator1 (
		 .OUT(VDD1V8),
		 .VIN3(VDD3V3),
		 .GNDO(VSS),
		 .EN(dpower),
		 .GNDR(VSS),
		 .VDDO(VDD3V3),
		 .VDDR(VDD3V3),
		 .VDD(VDD1V8),
		 .ENB(dground)
	);
`ifdef LVS
	aregc01_3v3 regulator2 (
		 .OUT(VDD1V8),
		 .VIN3(VDD3V3),
		 .GNDO(VSS),
		 .EN(dpower),
		 .GNDR(VSS),
		 .VDDO(VDD3V3),
		 .VDDR(VDD3V3),
		 .VDD(VDD1V8),
		 .ENB(dground)
	);
`endif

	/* Power-on-reset */
	aporc02_3v3 por (
		 .POR(rst),
		 .PORB(rstn), // RESETn
		 .VDDA(VDD3V3),
		 .VSSA(VSS)
	);

	BU_3VX2 por_level (
`ifdef LVS
		 .gnd(VSS),
		 .vdd3(VDD1V8),
`endif
		 .A(rst),
		 .Q(rst_lv)
	);

	BU_3VX2 por_leveln (
`ifdef LVS
		.gnd(VSS),
		.vdd3(VDD1V8),
`endif
		.A(rstn),
		.Q(rstn_lv)
	);
	

	BBC4F qspi_data_pads [3:0] (
		.PAD(qspi_io),
		.EN(fdoe),
		.A(fdo),
		.PO(),
		.GNDO(VSS),
		.GNDR(VSS),
		.VDD(VDD1V8),
		.VDDO(VDD3V3),
		.VDDR(VDD3V3),
		.PI(dground),
		.Y(fdi)
	);
	
	BT4F qspi_sclk_pad (
		.PAD(qspi_sclk),
		.EN(dground),
		.A(fsclk),
		.GNDO(VSS),
		.GNDR(VSS),
		.VDD(VDD1V8),
		.VDDO(VDD3V3),
		.VDDR(VDD3V3)
	);
	
	BT4F qspi_cen_pad (
		.PAD(qspi_ce),
		.EN(dground),
		.A(fcen),
		.GNDO(VSS),
		.GNDR(VSS),
		.VDD(VDD1V8),
		.VDDO(VDD3V3),
		.VDDR(VDD3V3)
	);


	<% for (let i = 0; i < dacComps.length; i++) { %>
	wire [9:0] dac_data_<%=i%>;
	wire dac_en_<%=i%>;
	wire dac_vrefh_sel_<%=i%>;
	<% } %>
	<% for (let i = 0; i < adcComps.length; i++) { %>
	wire [9:0] adc_data_<%=i%>;
	wire adc_eoc_<%=i%>;
	wire adc_start_<%=i%>;
	wire [2:0] adc_mux_sel_<%=i%>;
	wire adc_en_<%=i%>;
	wire adc_vrefh_sel_<%=i%>;
	wire real adc_input_<%=i%>_a;
	wire real adc_input_<%=i%>_b;
	wire real adc_input_<%=i%>;
	<% } %>

<% if (bgCount) { %>
	<% for (let i = 0; i < bgCount; i++) { %>
	wire real bandgap_out_<%=i%>;
	wire bg_ena_3v_<%=i%>;
	/* Level shift up for the bandgap enable signal */
	LS_3VX2 bg_ena_level_<%=i%> (
		.VDD3V3(VDD3V3),
		.VDD1V8(VDD1V8),
		.VSSA(VSS),
		.A(bg_en_<%=i%>),
		.Q(bg_ena_3v_<%=i%>)
	);

	/* Bandgap */
	abgpc01_3v3 bandgap_<%=i%> (
		.EN(bg_ena_3v_<%=i%>),
		.VBGP(bandgap_out_<%=i%>),
		.VSSA(VSS),
		.VDDA(VDD3V3),
		.VBGVTN()
	);
	<% } %>
<% } %>
	<% for (let i = 0; i < dacComps.length; i++) { %>
	
	// DAC_<%=i%>
	wire real dac_vrefl_<%=i%>;
	<%
		let opAmpBiasName =
			(i == 0 && demoMode) ?
				`opamp_bias` :
				`opamp_bias_${i}`;
		if (i >= cmpCount) {
	%>
	wire real dac_vrefh_<%=i%>;
	<%
	}
	%>

	AMUX2_3V dac_vrefh_mux_<%=i%> (
		.VDD3V3(VDD3V3),
		.VDD1V8(VDD1V8),
		.VSSA(VSS),
		.AIN1(VREFH),
		.AIN2(<%= (bgCount && !demoMode)? 'bandgap_out_0': 'VDD3V3' %>),  <% // connected to VREFH if the bandgap vref is not added to the SoC %>
		.AOUT(dac_vrefh_<%=i%>),
		.SEL(dac_vrefh_sel_<%=i%>)
	);

	AMUX2_3V dac_vrefl_mux_<%=i%> (
		.VDD3V3(VDD3V3),
		.VDD1V8(VDD1V8),
		.VSSA(VSS),
		.AIN1(VREFL),
		.AIN2(VSS),  <% // connected to VREFH if the bandgap vref is not added to the SoC %>
		.AOUT(dac_vrefl_<%=i%>),
		.SEL(dac_vrefh_sel_<%=i%>)
	);

	adacc01_3v3 DAC_<%=i%>(
		.OUT(dac_out_<%=i%>),
		.D(dac_data_<%=i%>),
		.EN(dac_en_<%=i%>),
		.VREFH(dac_vrefh_<%=i%>),
		.VREFL(dac_vrefl_<%=i%>),
		.VDD(VDD1V8),
		.VDDA(VDD3V3),
		.VSS(VSS),
		.VSSA(VSS)
	);

	/* Level shift the DAC enable */
	wire dac_en_0_3v;
	LS_3VX2 dac_ena_level_<%=i%> (
	   .VDD3V3(VDD3V3),
	   .VDD1V8(VDD1V8),
	   .VSSA(VSS),
	   .A(dac_en_<%=i%>),
	   .Q(dac_en_<%=i%>_3v)
	);

	wire real <%=opAmpBiasName%>;

	aopac01_3v3 voltagefollower_<%=i%> (
	   .OUT(OUT<%=i%>),
	   .EN(dac_en_<%=i%>_3v),
	   .IB(<%=opAmpBiasName%>),
	   .INN(OUT<%=i%>),
	   .INP(dac_out_<%=i%>),
	   .VDDA(VDD3V3),
	   .VSSA(VSS)
	);

	acsoc02_3v3 voltagefollower_bias_0 (
	   .EN(dac_en_<%=i%>_3v),
	   .VDDA(VDD3V3),
	   .VSSA(VSS),
	   .CS_8U(),
	   .CS_4U(),
	   .CS_2U(<%=opAmpBiasName%>),
	   .CS_1U(<%=opAmpBiasName%>)
	);
	<% } %>

	<% for (let i = 0; i < adcComps.length; i++) { %>
	// ADC_<%=i%>
	wire real adc_vrefl_<%=i%>;
	<%
		let AINs = [];
		if (demoMode) {
			let start =
				(i == 0) ? 0
				:
				((i + 1) * 4) + (i >= cmpCount ? 1 : 0) * 2 // Trust me, I hate this as much as you do.
			;
			AINs = [start, start + 1, start + 2, start + 3, 4, 5, 6, 7];
			AINs = AINs.map(ain=> `AN${ain}`)
		} else {
			AINs = [0, 1, 2, 3, 4, 5, 6, 7].map(ain=> `ADC_${i}_AN${ain}`)
		}
	%>

	<% for (let ain = 0; ain < AINs.length && !demoMode; ain++) { %>
	APR00DF <%=AINs[ain]%>_pad (
		.GNDO(VSS),
		.GNDR(VSS),
		.PAD(<%=AINs[ain]%>),
		.VDD(VDD1V8),
		.VDDO(VDD3V3),
		.VDDR(VDD3V3)
	);
	<% } %>

	AMUX2_3V adc_vrefh_mux_<%=i%> (
		.VDD3V3(VDD3V3),
		.VDD1V8(VDD1V8),
		.VSSA(VSS),
		.AIN1(VREFH),
		.AIN2(<%= (bgCount && !demoMode)? 'bandgap_out_0': 'VDD3V3' %>), <% // connect this to VREFH if the bandgap vref is not added to the SoC %>
		.AOUT(adc_vrefh_<%=i%>),
		.SEL(adc_vrefh_sel_<%=i%>)
	);

	AMUX2_3V adc_vrefl_mux_<%=i%> (
		.VDD3V3(VDD3V3),
		.VDD1V8(VDD1V8),
		.VSSA(VSS),
		.AIN1(VREFL),
		.AIN2(VSS), <% // connect this to VREFH if the bandgap vref is not added to the SoC %>
		.AOUT(adc_vrefl_<%=i%>),
		.SEL(adc_vrefh_sel_<%=i%>)
	);

	AMUX4_3V adc_AMUX4x1_<%=i%>_a (
		.VDD3V3(VDD3V3),
		.VDD1V8(VDD1V8),
		.VSSA(VSS),
		.AIN1(<%=AINs[0]%>), .AIN2(<%=AINs[1]%>), .AIN3(<%=AINs[2]%>), .AIN4(<%=AINs[3]%>),
		.AOUT(adc_input_<%=i%>_a),
		.SEL(adc_mux_sel_<%=i%>[1:0])
	);
	<% let current = 4 * (i + 1); %>
									
	AMUX4_3V adc_AMUX4x1_<%=i%>_b (
		.VDD3V3(VDD3V3),
		.VDD1V8(VDD1V8),
		.VSSA(VSS),
		.AIN1(<%=AINs[4]%>), .AIN2(<%=AINs[5]%>), .AIN3(<%=AINs[6]%>), .AIN4(<%=AINs[7]%>),
		.AOUT(adc_input_<%=i%>_b),
		.SEL(adc_mux_sel_<%=i%>[1:0])
	);
									
	AMUX2_3V adc_AMUX2x1_<%=i%> (
		.VDD3V3(VDD3V3),
		.VDD1V8(VDD1V8),
		.VSSA(VSS),
		.AIN1(adc_input_<%=i%>_a),
		.AIN2(adc_input_<%=i%>_b),
		.AOUT(adc_input_<%=i%>),
		.SEL(adc_mux_sel_<%=i%>[2])
	);

	aadcc01_3v3 ADC_<%=i%>(
		.VIN(adc_input_<%=i%>),
		.D(adc_data_<%=i%>),
		.EOC(adc_eoc_<%=i%>),
		.CLK(adc_clk_<%=i%>),
		.EN(adc_en_<%=i%>),
		.START(adc_start_<%=i%>),
		.VREFH(adc_vrefh_<%=i%>),
		.VREFL(adc_vrefl_<%=i%>),
		.VDD(VDD1V8),
		.VDDA(VDD3V3),
		.VSS(VSS),
		.VSSA(VSS) 
	);
<% } %>
<% if (adcComps.length) { %>
	APR00DF adc_low_pad (
		 .GNDO(VSS),
		 .GNDR(VSS),
		 .PAD(VREFL),
		 .VDD(VDD1V8),
		 .VDDO(VDD3V3),
		 .VDDR(VDD3V3)
	);

	APR00DF adc_high_pad (
		 .GNDO(VSS),
		 .GNDR(VSS),
		 .PAD(VREFH),
		 .VDD(VDD1V8),
		 .VDDO(VDD3V3),
		 .VDDR(VDD3V3)
	);
<% } %>


<%
for (let i in dacComps) {
	if (dacComps[i].options.io_dac_out == 'APR00DF') {
		let j = i;
		if (demoMode && i == 0) {
			j = '';
		}
%>
	APR00DF dac_out<%=j%>_pad (
		.GNDO(VSS),
		.GNDR(VSS),
		.PAD(OUT<%=i%>),
		.VDD(VDD1V8),
		.VDDO(VDD3V3),
		.VDDR(VDD3V3)
	);
<%
	}
}
%>

<%
for (let i in pwmComps) {
	if (pwmComps[i].options.io_pwm == 'APR00DF') {
%>
	APR00DF pwm_pad_<%=i%> (
		.GNDO(VSS),
		.GNDR(VSS),
		.PAD(PWMO_<%=i%>),
		.VDD(VDD1V8),
		.VDDO(VDD3V3),
		.VDDR(VDD3V3)
	);
<%
	}
}
%>

<% for (let i = 0; i < ANCount && demoMode; i++) { %>
	APR00DF an<%=i%>_pad (
		.GNDO(VSS),
		.GNDR(VSS),
		.PAD(AN<%=i%>),
		.VDD(VDD1V8),
		.VDDO(VDD3V3),
		.VDDR(VDD3V3)
	);
<% } %>

<% for (var i = 0; i < apbSPICount; i++) { %>
	<%
		let apbSPIMSIName = "APB_SPI_MSI_" + i;
		if (doJTAGPortShare && i == 0) {
			apbSPIMSIName = "tck__APB_SPI_MSI_0";
		}
	%>
	ICF apb_spi_msi_pad_<%=i%> (
		.PAD(<%=apbSPIMSIName%>),
		.PO(),
		.GNDO(VSS),
		.GNDR(VSS),
		.VDD(VDD1V8),
		.VDDO(VDD3V3),
		.VDDR(VDD3V3),
		.PI(dground),
		.Y(APB_MSI_<%=i%>)
	);
	
	BT4F apb_spi_mso_pad_<%=i%> (
		.PAD(APB_SPI_MSO_<%=i%>),
		.EN(dground),
		.A(APB_MSO_<%=i%>),
		.GNDO(VSS),
		.GNDR(VSS),
		.VDD(VDD1V8),
		.VDDO(VDD3V3),
		.VDDR(VDD3V3)
	);
	BT4F apb_spi_ssn_pad_<%=i%> (
		.PAD(APB_SPI_SSn_<%=i%>),
		.EN(dground),
		.A(APB_SSn_<%=i%>),
		.GNDO(VSS),
		.GNDR(VSS),
		.VDD(VDD1V8),
		.VDDO(VDD3V3),
		.VDDR(VDD3V3)
	);
	BT4F apb_spi_sclk_pad_<%=i%> (
		.PAD(APB_SPI_SCLK_<%=i%>),
		.EN(dground),
		.A(APB_SCLK_<%=i%>),
		.GNDO(VSS),
		.GNDR(VSS),
		.VDD(VDD1V8),
		.VDDO(VDD3V3),
		.VDDR(VDD3V3)
	);
<% } %>

<% for (var i = 0; i < ahbSPICount; i++) { %>
	ICF ahb_spi_msi_pad_<%=i%> (
		.PAD(AHB_SPI_MSI_<%=i%>),
		.PO(),
		.GNDO(VSS),
		.GNDR(VSS),
		.VDD(VDD1V8),
		.VDDO(VDD3V3),
		.VDDR(VDD3V3),
		.PI(dground),
		.Y(AHB_MSI_<%=i%>)
	);
	
	BT4F ahb_spi_mso_pad_<%=i%> (
		.PAD(AHB_SPI_MSO_<%=i%>),
		.EN(dground),
		.A(AHB_MSO_<%=i%>),
		.GNDO(VSS),
		.GNDR(VSS),
		.VDD(VDD1V8),
		.VDDO(VDD3V3),
		.VDDR(VDD3V3)
	);

	BT4F ahb_spi_ssn_pad_<%=i%> (
		.PAD(AHB_SPI_SSn_<%=i%>),
		.EN(dground),
		.A(AHB_SSn_<%=i%>),
		.GNDO(VSS),
		.GNDR(VSS),
		.VDD(VDD1V8),
		.VDDO(VDD3V3),
		.VDDR(VDD3V3)
	);

	BT4F ahb_spi_sclk_pad_<%=i%> (
		.PAD(AHB_SPI_SCLK_<%=i%>),
		.EN(dground),
		.A(AHB_SCLK_<%=i%>),
		.GNDO(VSS),
		.GNDR(VSS),
		.VDD(VDD1V8),
		.VDDO(VDD3V3),
		.VDDR(VDD3V3)
	);
<% } %>

<% if (uartComps.length) { %>
	<% uartComps.forEach(function(u, ind) { %>
	<%
		let i = ind;
		let RsRxName = "RsRx_" + i;
		let RsTxName = "RsTx_" + i;
		let TxBufferName = "RsTxCore_" + i;
		if (doJTAGPortShare && i == 0) {
			RsRxName = "tms__RsRx_0";
			RsTxName = "tdo__RsTx_0";
			TxBufferName = "tdo_tx0_mux_o";
		}
		if (doJTAGPortShare && i == 1) {
			RsRxName = "tdi__RsRx_1";
		}
	%>
	
	wire RsRxCore_<%=ind%>;
	wire RsTxCore_<%=ind%>;
	
		<% if (u.options.io_uart_rx  === 'ICF') { %>
	// UART Input Buffer
	ICF ser_rx_buf<%=ind%> (
		.PAD(<%=RsRxName%>),
		.PO(),
		.GNDO(VSS),
		.GNDR(VSS),
		.VDD(VDD1V8),
		.VDDO(VDD3V3),
		.VDDR(VDD3V3),
		.PI(dground),
		.Y(RsRxCore_<%=ind%>)
	);
		<% } else { %>
	assign RsRxCore_<%=ind%> = <%=RsRxName%>;
		<% }
		if (u.options.io_uart_tx  === 'BT4F') { %>

	// UART OUTPUT Buffer
	BT4F ser_tx_buf<%=ind%> (
		.PAD(<%=RsTxName%>),
		.EN(dground),
		.A(<%=TxBufferName%>),
		.GNDO(VSS),
		.GNDR(VSS),
		.VDD(VDD1V8),
		.VDDO(VDD3V3),
		.VDDR(VDD3V3)
	);
		<% } else { %>
	assign RsTxCore_<%=ind%> = <%=RsTxName%>;
		<% }
	}) %>
<% } %>
<% if (apbGPIOComps.length) { %>
	<% for (var i = 0; i < apbGPIOComps.length; i++) { %>
	wire [<%= parseInt(apbGPIOComps[i].options.pin_size || 16) - 1 %>:0] APB_GPIOIN<%=i%>;
	wire [<%= parseInt(apbGPIOComps[i].options.pin_size || 16) - 1 %>:0] APB_GPIOOUT<%=i%>;
	wire [<%= parseInt(apbGPIOComps[i].options.pin_size || 16) - 1 %>:0] APB_GPIOPU<%=i%>;
	wire [<%= parseInt(apbGPIOComps[i].options.pin_size || 16) - 1 %>:0] APB_GPIOPD<%=i%>;
	wire [<%= parseInt(apbGPIOComps[i].options.pin_size || 16) - 1 %>:0] APB_GPIOEN<%=i%>;
	<% } %>
	<% apbGPIOComps.forEach(function(u, ind) { %>
	BBCUD4F APB_GPIO_buf_<%=ind%> [<%=(parseInt(u.options.pin_size) || 16) - 1 %>: 0] (
		.A(APB_GPIOOUT<%=ind%>),
		.EN(APB_GPIOEN<%=ind%>),
		.GNDO(VSS),
		.GNDR(VSS),
		.PAD(APB_GPIO<%=ind%>),
		.PDEN(APB_GPIOPD<%=ind%>),
		.PI(dground),
		.PO(),
		.PUEN(APB_GPIOPU<%=ind%>),
		.VDD(VDD1V8),
		.VDDO(VDD3V3),
		.VDDR(VDD3V3),
		.Y(APB_GPIOIN<%=ind%>)
	);
	<% }) %>
<% } %>
<% if (ahbGPIOComps.length) { %>
	<% for (var i = 0; i < ahbGPIOComps.length; i++) { %>
	wire [<%= parseInt(ahbGPIOComps[i].options.pin_size || 16) - 1 %>:0] AHB_GPIOIN<%=i%>;
	wire [<%= parseInt(ahbGPIOComps[i].options.pin_size || 16) - 1 %>:0] AHB_GPIOOUT<%=i%>;
	wire [<%= parseInt(ahbGPIOComps[i].options.pin_size || 16) - 1 %>:0] AHB_GPIOPU<%=i%>;
	wire [<%= parseInt(ahbGPIOComps[i].options.pin_size || 16) - 1 %>:0] AHB_GPIOPD<%=i%>;
	wire [<%= parseInt(ahbGPIOComps[i].options.pin_size || 16) - 1 %>:0] AHB_GPIOEN<%=i%>;
	<% } %>
	<% ahbGPIOComps.forEach(function(u, ind) { %>
	BBCUD4F AHB_GPIO_buf_<%=ind%> [<%=(parseInt(u.options.pin_size) || 16) - 1 %>: 0] (
		.A(AHB_GPIOOUT<%=ind%>),
		.EN(AHB_GPIOEN<%=ind%>),
		.GNDO(VSS),
		.GNDR(VSS),
		.PAD(AHB_GPIO<%=ind%>),
		.PDEN(AHB_GPIOPD<%=ind%>),
		.PI(dground),
		.PO(),
		.PUEN(AHB_GPIOPU<%=ind%>),
		.VDD(VDD1V8),
		.VDDO(VDD3V3),
		.VDDR(VDD3V3),
		.Y(AHB_GPIOIN<%=ind%>)
	);
	<% }) %>
<% } %>

<% if (i2cComps.length) { %>
	<% for (var i = 0; i < i2cComps.length; i++) { %>
	wire scl_i_<%=i%>;	    // SCL-line input
	wire scl_o_<%=i%>;	    // SCL-line output (always 1'b0)
	wire scl_oen_o_<%=i%>; // SCL-line output enable (active low)
	wire sda_i_<%=i%>;     // SDA-line input
	wire sda_o_<%=i%>;	    // SDA-line output (always 1'b0)
	wire sda_oen_o_<%=i%>; // SDA-line output enable (active low)
	<% } %>
	<% i2cComps.forEach(function(u, ind) { %>
	BBCUD4F i2c_buf_cl_<%=ind%> (
		.A(scl_o_<%=ind%>),
		.EN(scl_oen_o_<%=ind%>),
		.GNDO(VSS),
		.GNDR(VSS),
		.PAD(i2c_cl_<%=ind%>),
		.PDEN(dground),
		.PI(dground),
		.PO(),
		.PUEN(dground),
		.VDD(VDD1V8),
		.VDDO(VDD3V3),
		.VDDR(VDD3V3),
		.Y(scl_i_<%=ind%>)
	);
	BBCUD4F i2c_buf_da_<%=ind%> (
		.A(sda_o_<%=ind%>),
		.EN(sda_oen_o_<%=ind%>),
		.GNDO(VSS),
		.GNDR(VSS),
		.PAD(i2c_da_<%=ind%>),
		.PDEN(dground),
		.PI(dground),
		.PO(),
		.PUEN(dground),
		.VDD(VDD1V8),
		.VDDO(VDD3V3),
		.VDDR(VDD3V3),
		.Y(sda_i_<%=ind%>)
	);

	<% }) %>
<% } %>

	<%
	for (let i = 0; i < cmpCount; i++) {
		let AINs = [];
		if (demoMode) {
			let start =	4 + ((i + 1) * 4); // Trust me, I hate this as much as you do.
			AINs = [`AN${start}`, `AN${start + 1}`];
		} else {
			AINs = [`comparator_${i}_AN0`, `comparator_${i}_AN1`];
		}
	%>
	// APB Comparator

	acmpc01_3v3 comparator_<%=i%> (
		.OUT(comp_out_<%=i%>),
		.EN(comp_ena_3v_<%=i%>),
		.IBN(bias400n_<%=i%>),
		.INN(comp_ninput_<%=i%>),	// multiplexed
		.INP(comp_pinput_<%=i%>),	// multiplexed
		.VDDA(VDD3V3),
		.VSSA(VSS)
	);

	/* Bias for comparator */
	acsoc01_3v3 comp_bias_<%=i%> (
		.EN(comp_ena_3v_<%=i%>),
		.VSSA(VSS),
		.VDDA(VDD3V3),
		.CS0_200N(bias400n_<%=i%>),
		.CS1_200N(bias400n_<%=i%>),
		.CS2_200N(),
		.CS3_200N()
	);

	LS_3VX2 comp_ena_level_<%=i%> (
		.VDD3V3(VDD3V3),
		.VDD1V8(VDD1V8),
		.VSSA(VSS),
		.A(comp_ena_<%=i%>),
		.Q(comp_ena_3v_<%=i%>)
		);

	/* Level shift down */

	BU_3VX2 comp_out_level_<%=i%> (
`ifdef LVS
		.gnd(VSS),
		.vdd3(VDD1V8),
`endif
		.A(comp_out_<%=i%>),
		.Q(comp_out_lv_<%=i%>)
	);

	AMUX2_3V comp_pinput_mux_<%=i%> (
		.VDD3V3(VDD3V3),
		.VDD1V8(VDD1V8),
		.VSSA(VSS),
		.AIN1(dac_out_<%=i%>),
		.AIN2(<%=AINs[0]%>),
		.AOUT(comp_pinput_<%=i%>),
		.SEL(comp_pinputsrc_<%=i%>[0])
	);

	AMUX2_3V comp_ninput_mux_<%=i%> (
		.VDD3V3(VDD3V3),
		.VDD1V8(VDD1V8),
		.VSSA(VSS),
		.AIN1(dac_out_<%=i%>),
		.AIN2(<%=AINs[1]%>),
		.AOUT(comp_ninput_<%=i%>),
		.SEL(comp_ninputsrc_<%=i%>[0])
	);

	// End of APB Comparator
	<% } %>

`ifdef JTAG
	// to scan chain
	wire tap_tdi_o, tap_tdo_i, tap_se_o;

	// to the pads
	wire tdo_pad_o, tdo_padoe_o;
	wire tms_pad_i, tck_pad_i, trstn_pad_i, tdi_pad_i;

	<% if (doJTAGPortShare) { %>

	assign tdo_pad = tdo_pad_o;
	assign tdo_padoe = tdo_padoe_o;

	wire jtag_mux_sel;

	ICF jtag_en_pad (
		.PAD(jtag_en),
		.PO(),
		.GNDO(VSS),
		.GNDR(VSS),
		.VDD(VDD1V8),
		.VDDO(VDD3V3),
		.VDDR(VDD3V3),
		.PI(dground),
		.Y(jtag_mux_sel)
	);

	MU2X2 tdo_tx0_mux (
`ifdef LVS
		.gnd(VSS),
		.vdd(VDD1V8),
`endif
		.IN0(RsTxCore_0),
		.IN1(tdo_pad_o),
		.Q(tdo_tx0_mux_o),
		.S(jtag_mux_sel)
	);

	MU2X2 tms_mux (
`ifdef LVS
		.gnd(VSS),
		.vdd(VDD1V8),
`endif
		.IN0(dground),
		.IN1(RsRxCore_0),
		.Q(tms_pad_i),
		.S(jtag_mux_sel)
	);

	assign tck_pad_i = APB_MSI_0;
	assign tdi_pad_i = RsRxCore_1;
	
	<% } else { %> 

	assign tdo_pad = tdo_pad_o;
	assign tdo_padoe = tdo_padoe_o;

	// TAP output pads
	BT4F tap_tdo_pad (
		.PAD(tdo_pad),
		.EN(dground),
		.A(tdo_pad_o),
		.GNDO(VSS),
		.GNDR(VSS),
		.VDD(VDD1V8),
		.VDDO(VDD3V3),
		.VDDR(VDD3V3)
	);

	BT4F tap_tdo_padoe (
		.PAD(tdo_padoe),
		.EN(dground),
		.A(tdo_padoe_o),
		.GNDO(VSS),
		.GNDR(VSS),
		.VDD(VDD1V8),
		.VDDO(VDD3V3),
		.VDDR(VDD3V3)
	);

	ICF tap_tms_pad (
		.PAD(tms_pad),
		.PO(),
		.GNDO(VSS),
		.GNDR(VSS),
		.VDD(VDD1V8),
		.VDDO(VDD3V3),
		.VDDR(VDD3V3),
		.PI(dground),
		.Y(tms_pad_i)
	);

	ICF tap_tck_pad (
		.PAD(tck_pad),
		.PO(),
		.GNDO(VSS),
		.GNDR(VSS),
		.VDD(VDD1V8),
		.VDDO(VDD3V3),
		.VDDR(VDD3V3),
		.PI(dground),
		.Y(tck_pad_i)
	);

	ICF tap_trstn_pad (
		.PAD(trstn_pad),
		.PO(),
		.GNDO(VSS),
		.GNDR(VSS),
		.VDD(VDD1V8),
		.VDDO(VDD3V3),
		.VDDR(VDD3V3),
		.PI(dground),
		.Y(trstn_pad_i)
	);

	ICF tap_tdi_pad (
		.PAD(tdi_pad),
		.PO(),
		.GNDO(VSS),
		.GNDR(VSS),
		.VDD(VDD1V8),
		.VDDO(VDD3V3),
		.VDDR(VDD3V3),
		.PI(dground),
		.Y(tdi_pad_i)
	);

	<% } %>
`endif

	wire [25:0] stcalib;		/* Dummy */

`ifdef RTL
	CORTEXM0_EF01 u_cortexm0ds0 (
        .FCLK(HCLK), 
        .SCLK(HCLK), 
        .HCLK(HCLK), 
    .DCLK(), 
		.HRESETn     (HRESETn),
		.HADDR       (HADDR[31:0]),
		.HBURST      (HBURST[2:0]),
		.HMASTLOCK   (HMASTLOCK),
		.HPROT       (HPROT[3:0]),
		.HSIZE       (HSIZE[2:0]),
		.HTRANS      (HTRANS[1:0]),
		.HWDATA      (HWDATA[31:0]),
		.HWRITE      (HWRITE),
		.HRDATA      (HRDATA[31:0]),
		.HREADY      (HREADY),
		.HRESP       (HRESP),

		.NMI         (dground),
		.IRQ         (IRQ[31:0]),
		.TXEV        (),
		.RXEV        (dground),
		.LOCKUP      (LOCKUP),
		.SYSRESETREQ (),
		.SLEEPING    (),
		.STCLKEN     (dground),
		.STCALIB     (stcalib)
	);
`else

	wire chain_w1, chain_w2;
	wire [2:0] codehintde;
	wire [33:0] wicsense;
	wire [27:0] ecorevnum;
	wire [7:0] irqlatency;

	CORTEXM0_EF01
	u_cortexm0ds0 (
`ifdef LVS
		.VSS(VSS),
		.VDD(VDD1V8),
`endif
        .FCLK(HCLK), 
        .SCLK(HCLK), 
        .HCLK(HCLK), 
    	.DCLK(), 
    	.PORESETn(), 
    	.DBGRESETn(),
        .HRESETn(HRESETn), 
    	.SWCLKTCK(), 
        .HADDR(HADDR[31:0]), 
        .HBURST(HBURST[2:0]), 
        .HMASTLOCK(HMASTLOCK), 
        .HPROT       (HPROT[3:0]),
		.HSIZE       (HSIZE[2:0]),
		.HTRANS      (HTRANS[1:0]),
		.HWDATA      (HWDATA[31:0]),
		.HWRITE      (HWRITE),
		.HRDATA      (HRDATA[31:0]),
		.HREADY      (HREADY),
		.HRESP       (HRESP),

		.HMASTER(),        // o/p ignore 
		.CODENSEQ(),       // o/p ignore 
		.CODEHINTDE(codehintde),     // o/p ignore 
		.SPECHTRANS(), 
		.SWDITMS(), .TDI(), .SWDO(), .SWDOEN(), .DBGRESTART(),
		.DBGRESTARTED(), .EDBGRQ(), .HALTED(), 
     
        .NMI         (dground),
		.IRQ         (IRQ[31:0]),
		.TXEV        (),
		.RXEV        (dground),
		.LOCKUP      (LOCKUP),
		.SYSRESETREQ (),
		.SLEEPING    (),
		.STCLKEN     (dground),
		.STCALIB     (stcalib),

		.IRQLATENCY(irqlatency), .ECOREVNUM(ecorevnum), 
		.GATEHCLK(),           // ignore
		.SLEEPDEEP(),          // ignore
     	
		.WAKEUP(), .WICSENSE(wicsense), .SLEEPHOLDREQn(),
     	.SLEEPHOLDACKn(), 
	 	.WICENREQ(dground), 
		.WICENACK(), 
		.CDBGPWRUPREQ(), 
		.CDBGPWRUPACK(dground), 
     	
        .SE(dground),
        .RSTBYPASS(dpower_1v8), // hi
     
     	// Connect to the JTAG TAP
`ifdef JTAG 	
		.test_mode(tap_se_o), 
`else 
		.test_mode(dground), 
`endif
		.DFT_sdi_1(tap_tdi_o), 
		.DFT_sdo_1(chain_w1), 
		.DFT_sdi_2(chain_w1), 
		.DFT_sdo_2(chain_w2),
     	.DFT_sdi_3(chain_w2), 
		.DFT_sdo_3(tap_tdo_i)
     );
`endif

	XSPRAMBLP_4096X32_M16P BANK0 (
`ifdef LVS
        .VSSM(VSS),
        .VDD18M(VDD1V8),
`endif
		.Q(SRAMRDATA),
		.D(SRAMWDATA),
		.A(SRAMADDR),
		.CLK(HCLK),
		.CEn(SRAMCS0),
		.WEn(WEn),
		.RDY()
	);

	DIGITALCORE core (
`ifdef LVS
        .gnd (VSS),
        .vdd (VDD1V8),
`endif
		.HCLK(HCLK),
		.RESETn(rstn_lv),

		<% for (let i = 0; i < adcComps.length; i++) { %>
		.adc_clk_<%=i%>(adc_clk_<%=i%>),
		.adc_en_<%=i%>(adc_en_<%=i%>),
		.adc_start_<%=i%>(adc_start_<%=i%>),
		.adc_eoc_<%=i%>(adc_eoc_<%=i%>),
		.adc_data_<%=i%>(adc_data_<%=i%>),
		.adc_vrefh_sel_<%=i%>(adc_vrefh_sel_<%=i%>),

		.adc_mux_sel_<%=i%>(adc_mux_sel_<%=i%>),

		<% } %>
		<% for (let i = 0; i < dacComps.length; i++) { %>
		.dac_data_<%=i%>(dac_data_<%=i%>),
		.dac_en_<%=i%>(dac_en_<%=i%>),
		.dac_vrefh_sel_<%=i%>(dac_vrefh_sel_<%=i%>),
		<% } %>
		<%
		ahbuart.forEach(function(u, ind) { %>
		.RsRx_<%=ind%>(RsRxCore_<%=ind%>),
		.RsTx_<%=ind%>(RsTxCore_<%=ind%>),
		<% }) %>
`ifdef DBG
		<%= ('.DBGIO0(DBGIO0)' + ',') %>
		<%= ('.TOUT0(TOUT0)' + ',') %>
`endif
		<% for (var i = 0; i < apbGPIOCount; i++) {%>
		.APB_GPIOIN<%=i%>(APB_GPIOIN<%=i%>),
		.APB_GPIOOUT<%=i%>(APB_GPIOOUT<%=i%>),
		.APB_GPIOPU<%=i%>(APB_GPIOPU<%=i%>),
		.APB_GPIOPD<%=i%>(APB_GPIOPD<%=i%>),
		.APB_GPIOEN<%=i%>(APB_GPIOEN<%=i%>),
		<% } %>
		<% for (var i = 0; i < ahbGPIOCount; i++) {%>
		.AHB_GPIOIN<%=i%>(AHB_GPIOIN<%=i%>),
		.AHB_GPIOOUT<%=i%>(AHB_GPIOOUT<%=i%>),
		.AHB_GPIOPU<%=i%>(AHB_GPIOPU<%=i%>),
		.AHB_GPIOPD<%=i%>(AHB_GPIOPD<%=i%>),
		.AHB_GPIOEN<%=i%>(AHB_GPIOEN<%=i%>),
		<% } %>
		<% for (var i = 0; i < uartComps.length; i++) { %>
		.RsRx_<%=i%>(RsRxCore_<%=i%>),
		.RsTx_<%=i%>(RsTxCore_<%=i%>),
		<% } %>
		<% for (let i = 0; i < i2cComps.length; i++) { %>
		.scl_i_<%=i%>(scl_i_<%=i%>),	      // SCL-line input
		.scl_o_<%=i%>(scl_o_<%=i%>),	    // SCL-line output (always 1'b0)
		.scl_oen_o_<%=i%>(scl_oen_o_<%=i%>),  // SCL-line output enable (active low)
		.sda_i_<%=i%>(sda_i_<%=i%>),       // SDA-line input
		.sda_o_<%=i%>(sda_o_<%=i%>),	    // SDA-line output (always 1'b0)
		.sda_oen_o_<%=i%>(sda_oen_o_<%=i%>),  // SDA-line output enable (active low)
		<% } %>
		.fdi(fdi),        // data coming from the QPI flash
		.fdo(fdo),        // data going to the QPI flash
		.fdoe(fdoe),       // o/p enable controls for the tri-state bufers
		.fsclk(fsclk),      // flash clk
		.fcen(fcen),       // flash enable (active low)


		.HRESETn(HRESETn),
		.HADDR(HADDR),
		.HWDATA(HWDATA),
	
		.HWRITE(HWRITE),
		.HTRANS(HTRANS),
		.HBURST(HBURST),
		.HMASTLOCK(HMASTLOCK),
		.HPROT(HPROT),
		.HSIZE(HSIZE),
		.LOCKUP(LOCKUP),
		.HRDATA(HRDATA),
		.HRESP(HRESP),
		.HREADY(HREADY),
		.IRQ(IRQ),

	<% for (var i = 0; i < apbSPICount; i++) { %>
		.APB_MSI_<%=i%>(APB_MSI_<%=i%>),
		.APB_MSO_<%=i%>(APB_MSO_<%=i%>),
		.APB_SSn_<%=i%>(APB_SSn_<%=i%>),
		.APB_SCLK_<%=i%>(APB_SCLK_<%=i%>),
	<% } %>
	<% for (var i = 0; i < ahbSPICount; i++) { %>
		.AHB_MSI_<%=i%>(AHB_MSI_<%=i%>),
		.AHB_MSO_<%=i%>(AHB_MSO_<%=i%>),
		.AHB_SSn_<%=i%>(AHB_SSn_<%=i%>),
		.AHB_SCLK_<%=i%>(AHB_SCLK_<%=i%>),
	<% } %>

	<% for (var i = 0; i < pwmCount; i++) { %>
		.PWMO_<%=i%>(PWMO_<%=i%>),
	<% } %>
	<% for (var i = 0; i < bgCount; i++) { %>
		.bg_en_<%=i%>(bg_en_<%=i%>),
	<% } %>
	<% for (var i = 0; i < cmpCount; i++) { %>
		.comp_out_<%=i%>(comp_out_lv_<%=i%>),
		.comp_ena_<%=i%>(comp_ena_<%=i%>),
		.comp_pinputsrc_<%=i%>(comp_pinputsrc_<%=i%>),
		.comp_ninputsrc_<%=i%>(comp_ninputsrc_<%=i%>),
	<% } %>

		
		.RESET(rst_lv),           // SoC rst_lv
		.clk_hsi(clk_hsi),       // SoC clk_hsi_lv
		.clk_hse(clk_hse),       // SoC clk_hse_lv
		.clk_pll_in(clk_pll),
		
		.clk_pll_out(clk_pll_out),
		.pll_cp_ena_lv(pll_cp_ena_lv),
		.pll_vco_ena_lv(pll_vco_ena_lv),
		.pll_trim(pll_trim),
		.hsi_ena(hsi_ena),
		.hse_ena(hse_ena),

`ifdef JTAG
		// To the JTAG Port
		.tms_pad_i(tms_pad_i), 
        .tck_pad_i(tck_pad_i), 
		.trstn_pad_i(HRESETn),
		.tdi_pad_i(tdi_pad_i), 
		.tdo_pad_o(tdo_pad_o),

		// TO the CPU Core
		.sample_preload_select_o(tap_se_o),
		.tdi_o(tap_tdi_o), 
		.bs_chain_tdo_i(tap_tdo_i), 
`endif
		
		.SRAMRDATA(SRAMRDATA),
		.WEn(WEn),
		.SRAMWDATA(SRAMWDATA),
		.SRAMCS0(SRAMCS0),
		.SRAMCS1(),
		.SRAMCS2(),
		.SRAMCS3(),
		.SRAMADDR(SRAMADDR)  // SRAM address
	);

	VDDORPADF vddor_pad [1:0] (
	   .GNDO(VSS),
	   .GNDR(VSS),
	   .VDD(VDD1V8),
	   .VDDOR(VDD3V3)
	);

    GNDORPADF gndor_pad [4:0] (
	   .GNDOR(VSS),
	   .VDD(VDD1V8),
	   .VDDO(VDD3V3),
	   .VDDR(VDD3V3)
	);

	VDDPADF vdd1v8_pad [1:0] (
	   .GNDO(VSS),
	   .GNDR(VSS),
	   .VDD(VDD1V8),
	   .VDDO(VDD3V3),
	   .VDDR(VDD3V3)
	);
endmodule
