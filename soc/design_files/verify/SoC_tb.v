<% var reverseBaseAddress = {}
for (var addr in base_address) {
	reverseBaseAddress[base_address[addr].index] = base_address[addr]
}
var componentsMap = {}
for (var addr in base_address) {
	componentsMap[base_address[addr].ip.component.id] = base_address[addr]
}
var apbGPIOCount = 0;
var apbGPIOComps = [];
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
var adcComps = [];
var dacCount = 0;
var bgCount = 0;
var ahbClocks = [];

for (var addr in base_address) {
	if (base_address[addr].ip.category === 'APB GPIO') {
		apbGPIOCount++;
		apbGPIOComps.push(base_address[addr]);
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
		adcComps.push(base_address[addr]);
	} else if (base_address[addr].ip.category === 'APB DAC') {
		dacCount++;
	}
}

let demoMode = adcComps.reduce(
	(result, current)=> result && current.options.raptor_demo === "Yes",
	true
);
let ANCount = cmpCount * 2 + 4 + adcComps.length * 4;

let doJTAGPortShare = true;
%>
`timescale 1ns/1ns
/*
	This testbench is used to test the following related components
		+ DAC
		+ DAC Vref (BG)
		+ ADC
		+ ADC MUX
		+ ADC Vref (BG)
        + i2c
        + spi
        + pwm
        + tmr
        + comp
*/
`define DBG

module  SoC_tb ;
	<% if (!i2cCount) { %>
	initial $display("No i2c modules. i2c tests will fail.");
	<% } %>
	<% if ((ahbSPICount + apbSPICount) == 0) { %>
	initial $display("No SPI modules. SPI tests will fail.");
	<% } %>
	
	reg real   VDD3V3;
	reg real   VSSA;
	reg real   VDDA;
	reg real   VSS;

	<% for (let i = 0; i < ANCount && demoMode; i++) { %>
	wire real AN<%=i%>;
	<% } %>
	<%
	for (let i = 0; i < adcComps.length && !demoMode; i++) {
		for (let j = 0; j < 8; j++) {
	%>
	wire real ADC_<%=i%>_AN<%=j%>;
	<% 	
		}
	}
	%>

	reg real   VREFL;
	reg real   VREFH;

    reg real    XI;
	wire real   XO;

	<% for (let i = 0; i < dacCount; i++) { %>
	wire real OUT<%=i%>;
	<% } %>

	wire [31:0] DBGIO0;

	<% for (var i = 0; i < ahbGPIOComps.length; i++) { %>
	wire [<%= parseInt(ahbGPIOComps[i].options.pin_size || 16) - 1 %>:0] AHB_GPIO<%=i%>;
	<% } %>
	// APB GPIO Ports
	<% for (var i = 0; i < apbGPIOComps.length; i++) { %>
	wire [<%= parseInt(apbGPIOComps[i].options.pin_size || 16) - 1 %>:0] APB_GPIO<%=i%>;
	<% } %>

	<% for (var i = 0; i < pwmCount; i++) { %>
	output wire PWMO_<%=i%>;
	<% } %>

	tri1 i2c_da;
	tri1 i2c_cl;

	wire SPI_MSI, SPI_MSO, SPI_SSn, SPI_SCLK;

	wire TOUT0;

    // DBGIO Fields Extraction
	wire[7:0] test_id = DBGIO0[7:0];
	wire test_running = DBGIO0[16];
	wire test_passed = DBGIO0[17];

`ifdef MONITORS
	
    wire [9: 0] dac_data    = uut.dac_data_0;
	wire [9: 0] adc_data    = uut.adc_data_0;

	wire real amuxa         = uut.adc_input_0_a;
	wire real amuxb         = uut.adc_input_0_b;
	wire real amux          = uut.adc_input_0;

	wire [2:0] adc_mux_sel  = uut.adc_mux_sel_0;

`endif

    wire HRESETn            = uut.HRESETn;
	wire CLK                = uut.HCLK;

	assign AN0 = OUT0;
	assign AN1 = 0.5;
	assign AN2 = 1.0;
	assign AN3 = 1.5;
	assign AN4 = 2.0;
	assign AN5 = 1.25;
	assign AN6 = 0.75;
	assign AN7 = OUT0;
	<% for (let i = 8; i < ANCount; i++) { %>
	assign AN<%=i%> = 1.3;
	<% } %>

	wire [3:0] qspi_io;
	wire qspi_sclk;
	wire qspi_ce;
	
	<%=top%> uut (
		.VDD3V3(VDD3V3),
		.VSS(VSS),
		
		<% for (let i = 0; i < ANCount && demoMode; i++) { %>
		.AN<%=i%>(AN<%=i%>),
		<% } %>
		<%
		for (let i = 0; i < adcComps.length && !demoMode; i++) {
			for (let j = 0; j < 8; j++) {
		%>
		.ADC_<%=i%>_AN<%=j%>(ADC_<%=i%>_AN<%=j%>),
		<% 	
			}
		}
		%>

		.VREFL(VREFL),
		.VREFH(VREFH),
		.TOUT0(TOUT0),
		<% for (let i = 0; i < dacCount; i++) { %>
		.OUT<%=i%>(OUT<%=i%>),
		<% } %>
		.DBGIO0(DBGIO0),
		.XI(XI),
		.qspi_io(qspi_io),
		.qspi_sclk(qspi_sclk),
		.qspi_ce(qspi_ce),
		.XO(XO),

		// GPIO
		<% for (let i = 0; i < ahbGPIOCount; i++) { %>
		.AHB_GPIO<%=i%>(AHB_GPIO<%=i%>),
		<% } %>
		<% for (let i = 0; i < apbGPIOCount; i++) { %>
		.APB_GPIO<%=i%>(APB_GPIO<%=i%>),
		<% } %>

		// SPI Master Interface
		<% if (apbSPICount) { %>
		<% if (!doJTAGPortShare) { %>
		.APB_SPI_MSI_0(SPI_MSI),
		<% } else { %>
		.tck__APB_SPI_MSI_0(SPI_MSI),
		<% } %>
		.APB_SPI_MSO_0(SPI_MSO),
		.APB_SPI_SSn_0(SPI_SSn),
		.APB_SPI_SCLK_0(SPI_SCLK),
		<% } else if (ahbSPICount) { %>
		.AHB_SPI_MSI_0(SPI_MSI),
		.AHB_SPI_MSO_0(SPI_MSO),
		.AHB_SPI_SSn_0(SPI_SSn),
		.AHB_SPI_SCLK_0(SPI_SCLK),
		<% } %>

		// I2C
		<% if (i2cCount) { %>
		.i2c_cl_0(i2c_cl),
		.i2c_da_0(i2c_da),
		<% } %>

		// PWM
		<% for (var i = 0; i < pwmCount; i++) { %>
		.PWMO_<%=i%>(PWMO_<%=i%>),
		<% } %>

		// UART
		<%
		for (let i = 0; i < uartCount; i++) {
			if (!doJTAGPortShare || i > 1) {
		%>
 		.RsRx_<%=i%>(1'b0),
 		.RsTx_<%=i%>(),
		<%
			} else {
				if (i == 0) {
		%>
		.tms__RsRx_0(1'b0),
		.tdo__RsTx_0(),
		<%
				} else {
		%>	
		.tdi__RsRx_1(1'b0),
		.RsTx_1(),
		<%
				}
			}
		}
		%>

		<% if (!doJTAGPortShare) { %>
		// TAP Controller
		.tms_pad(1'b0),      // JTAG test mode select pad
		.tck_pad(1'b0),      // JTAG test clock pad
		.trstn_pad(1'b0),    // JTAG test reset pad
		.tdi_pad(1'b0)      // JTAG test data input pad
		<% } else { %>
		.jtag_en(1'b0)
		<% } %>
	);
	
	// Program Flash
	sst26vf064b flash(
		.SCK(qspi_sclk),
		.SIO(qspi_io),
		.CEb(qspi_ce)
	);


	// SPI Flash connected to the SPI master
	wire spi_flash_hold;
    assign spi_flash_hold = 1'b1;
    M23LC512 SPI_Slave (
        .SI_SIO0(SPI_MSO),
        .SO_SIO1(SPI_MSI),
        .SCK(SPI_SCLK),
        .CS_N(SPI_SSn),
        .SIO2(),
        .HOLD_N_SIO3(spi_flash_hold),
        .RESET(~HRESETn)
    );


	// Power up the system
	initial begin
		XI = 0.0;
		VREFH = 2.046;
		VREFL = 0.0;
		VDD3V3 = 0.0;
		VDDA = 0.0;
		#150
		VDD3V3 = 3.3;
		VDDA = 3.3;
		VREFH = 2.046;
		VREFL = 0.0;
		//XI = VDD3V3;
	end

    // 4-MHZ XTAL
    always begin
        #125;
        if(XI == 0.0)
            XI = VDD3V3;
        else
            XI = 0.0;
    end
    
	<% for (let i = 0; i < adcComps.length; i++) { %>
	//initial $monitor(OUT<%=i%>);
	<% } %>

	// Stop the simulation after 5M ticks
	// The test fails if we reach this point.
	initial begin
		#10_000_000;          // Max simulation time is 10msec
		$display("Test: %0X failed - Timeout", test_id );
		$finish();
	end

	/** Load S/W **/
	initial begin
	  $readmemh(`HEX_PATH, flash.I0.memory);
	end
	/** End Load S/W **/

	// exits the simulation when the test code terminates the test
	initial begin
		#100;
		@(posedge test_running);
		@(negedge test_running);
		if (test_passed) begin
			$display("Test: %0X passed", test_id );
			#100;
			$finish;
		end else begin
			$display("Test: %0X failed - Failure Code", test_id );
			#100;
			$finish;
		end
	end
	
    // ~~~~~~~~~~~~~~~
	// GPIO Loopback
    // ~~~~~~~~~~~~~~~
	<%
	for (var i = 0; i < ahbGPIOComps.length; i++) {
		let gpioSize = parseInt(ahbGPIOComps[i].options.pin_size || 16);
		let value = Math.floor(((1 << (gpioSize / 2)) - 1) / 2); //MUST MATCH WITH ONE IN TEST
	%>
	assign  AHB_GPIO<%=i%>[<%= gpioSize - 1 %>:<%= gpioSize / 2%>] = AHB_GPIO<%=i%>[<%= gpioSize / 2 - 1%>:<%=0%>] + <%=value%>;
	<% } %>
	<%
	for (var i = 0; i < apbGPIOComps.length; i++) {
		let gpioSize = parseInt(apbGPIOComps[i].options.pin_size || 16);
		let value = Math.floor(((1 << (gpioSize / 2)) - 1) / 2); //MUST MATCH WITH ONE IN TEST
	%>
	assign  APB_GPIO<%=i%>[<%= gpioSize - 1 %>:<%= gpioSize / 2%>] = APB_GPIO<%=i%>[<%= gpioSize / 2 - 1%>:<%=0%>] + <%=value%>;
	<% } %>


    // ~~~~~~~~~~~~~~~
	// PWM Verifier
    // ~~~~~~~~~~~~~~~
	reg [7:0] pwm_edge_count = 0;
	
	always @ (posedge PWMO_0)
		pwm_edge_count = pwm_edge_count + 1;
	
	always @(pwm_edge_count)
		if(pwm_edge_count==5)begin
			$display("Test: %0X passed", test_id );
			#100;
			$finish;
		end

    // ~~~~~~~~~~~~~~~
	// I2C Verifier
    // ~~~~~~~~~~~~~~~
	wire [15:0] i2c_data;
	i2c_slave_vip I2CSVIP(
		.scl(i2c_cl), .sda(i2c_da),
		.rst(~HRESETn), .clk(CLK),
		.i2c_data(i2c_data)
	);
	// Wait for 69 to be produced by the i2c master controller
	always@(i2c_data)
		if(i2c_data==69) begin
			$display("Test: %0X passed", test_id );
			#100;
			$finish;
		end


    // Performance reporting
    integer st,et,tm;
    initial begin
        @(posedge test_running);
        st=$time;
        @(negedge test_running);
        et=$time;
        tm = et - st;
        if(test_id=='he0) 
            $display("Performance Test took: %0d ns (%0d cycles - %0d Cycles/iterations)",tm, tm/100, tm/50000);
    end

	`ifdef CREATE_DUMPS
		`ifndef VCD_NAME
			`define VCD_NAME "SoC.tb.vcd"
		`endif
		initial begin 
			// Remove _ to use with offline scripts
			//$_dumpfile(`VCD_NAME); 
			//$_dumpvars(1, SoC_tb); 
			//$_dumpvars(1, uut);
			//$_dumpvars(0, uut.core);
		end
	`endif

endmodule