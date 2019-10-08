<%
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
let SPAddress = Number((memoryAddress << 4*4) + memSize * 1024).toString(16);
%>
/*
	This module has to start at address 0.
	It occupies 8 bytes (2 words) only
*/

//`default_nettype none

module AHB2TWROM
(
	//AHBLITE INTERFACE
		//Slave Select Signals
			input wire HSEL,
		//Global Signal
			input wire HCLK,
			input wire HRESETn,
		//Address, Control & Write Data
			input wire HREADY,
			input wire [31:0] HADDR,
			input wire [1:0] HTRANS,
			input wire HWRITE,
			input wire [2:0] HSIZE,
			input wire [31:0] HWDATA,
		// Transfer Response & Read Data
			output wire HREADYOUT,
			output wire [31:0] HRDATA
);

  assign HREADYOUT = 1'b1; // Always ready

// Registers to store Adress Phase Signals

  reg APhase_HSEL;
  reg APhase_HWRITE;
  reg [1:0] APhase_HTRANS;
  reg [31:0] APhase_HADDR;
  reg [2:0] APhase_HSIZE;

	// Change SP initial value based on the SoC SRAM configuration
	// PC value has to do with teh startup code.
  wire [31:0] SP = 32'h<%=SPAddress%>;
  wire [31:0] PC = 32'h00000101;

// Sample the Address Phase
  always @(posedge HCLK or negedge HRESETn)
  begin
	 if(!HRESETn)
	 begin
		APhase_HSEL <= 1'b0;
      APhase_HWRITE <= 1'b0;
      APhase_HTRANS <= 2'b00;
		APhase_HADDR <= 32'h0;
		APhase_HSIZE <= 3'b000;
	 end
    else if(HREADY)
    begin
      APhase_HSEL <= HSEL;
      APhase_HWRITE <= HWRITE;
      APhase_HTRANS <= HTRANS;
		APhase_HADDR <= HADDR;
		APhase_HSIZE <= HSIZE;
    end
  end

// Reading from memory
  assign HRDATA = APhase_HADDR[2] ? PC : SP;



endmodule