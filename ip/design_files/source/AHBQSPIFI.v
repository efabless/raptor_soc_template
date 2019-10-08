/*******************************************************************
 *
 * Module: AHBQSPIFI.v
 * Project: Raptor
 * Author: mshalan
 * Description: QPI Flash Interface to AHB-Lite Bridge
 *
 **********************************************************************/

module AHBQSPIFI(
    // AHB-Lite Bus Interface
  //Inputs
  input wire HSEL,
  input wire HCLK,
  input wire HRESETn,
  input wire [31:0] HADDR,
  input wire [1:0] HTRANS,
  input wire [31:0] HWDATA,
  input wire HWRITE,
  input wire HREADY,

  //Output
  output reg HREADYOUT,
  output /*reg*/ [31:0] HRDATA,
  
  // Flash Memory Interface
  output wire spi_clk,
  output wire spi_cs,
  inout wire [3:0] spi_io
);

  //State parameters
  localparam [1:0] st_idle = 2'b00;
  localparam [1:0] st_wait = 2'b01;
  localparam [1:0] st_rw = 2'b10;

  //Register select parameters
  localparam [3:0] REG0 = 4'h0;
  localparam [3:0] REG1 = 4'h4;
  localparam [3:0] REG2 = 4'h8;
  localparam [3:0] REG3 = 4'hC;

  //State machine registers
  reg [1:0] current_state;
  reg [1:0] next_state;
  reg [4:0] wait_reg;
  reg [4:0] wait_next;

  reg HREADYOUT_next;

  //Data Regs
  reg [31:0] d_reg0;
  reg [31:0] d_reg1;
  reg [31:0] d_reg2;
  reg [31:0] d_reg3;

  //AHB-Lite Address Phase Regs
  reg last_HSEL;
  reg [31:0] last_HADDR;
  reg last_HWRITE;
  reg [1:0] last_HTRANS;

// SPI FI Logic
    reg ctrl_spi_start;
    wire[3:0] spi_I, spi_O;
    wire spi_oe;
    wire[31:0] mem_addr = {12'd0, last_HADDR[19:0]};
    wire[31:0] mem_data;
    
    assign spi_I = spi_io;
    assign spi_io = spi_oe ? spi_O : 4'bzzzz;
    
    always @ (posedge HCLK or negedge HRESETn)
    if(!HRESETn)
        ctrl_spi_start <= 1'b0;
    else
        if(HREADY & HSEL)
            ctrl_spi_start <= 1'b1;
        else 
            ctrl_spi_start <= 1'b0;
            
	QSPIFI qspifi (
		.clk(HCLK),
		.reset(HRESETn),
		.ahb_addr(last_HADDR),
		.ctrl_addr_wr(1'b0),
		.ctrl_spi_start(ctrl_spi_start),
		.spi_data(mem_data),
		.spi_I(spi_I),
		.spi_O(spi_O),
		.spi_obuf_en(spi_oe),
		.spi_CS(spi_cs),
		.spi_clk(spi_clk)
		
	);



// AHB Interface Logic
  always@ (posedge HCLK)
  begin
    if(HREADY)
      begin
        last_HSEL         <= HSEL;
        last_HADDR        <= HADDR;
        last_HWRITE       <= HWRITE;
        last_HTRANS       <= HTRANS;
      end
  end

  //State Machine
  always @(posedge HCLK, negedge HRESETn)
  begin
    if(!HRESETn)
      begin
        current_state <= st_idle;
        HREADYOUT <= 1'b0;
        wait_reg <= 4'h0;
      end
    else
      begin
        current_state <= next_state;
        HREADYOUT <= HREADYOUT_next;
        wait_reg <= wait_next;
      end
  end

  //Next State Logic
  always @*
  begin
    next_state = current_state;
    HREADYOUT_next = 1'b0;
    wait_next = wait_reg;
    case(current_state)
      st_idle:
        if(HSEL & HREADY)
          begin
            next_state = st_wait;
            wait_next = 5'd29; 
          end
      st_wait:
        if(wait_reg == 0)
          begin
            next_state = st_idle;
            HREADYOUT_next = 1'b1;
          end
        else
          wait_next = wait_reg - 1'b1;
          
    endcase
  end

assign HRDATA = mem_data;
endmodule


