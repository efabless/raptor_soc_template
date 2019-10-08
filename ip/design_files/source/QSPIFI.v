/*******************************************************************
 *
 * Module: QSPIFI.v
 * Project: Raptor
 * Author: mshalan
 * Description: QPI Flash Interface 
 *
 **********************************************************************/


module QSPIFI #(parameter MODE=0)

(
  input wire clk,
  input wire reset,
  input wire [31:0] ahb_addr,   // has to be shifted by 8 bits to the left 
  input ctrl_addr_wr,
  input ctrl_spi_start,
  
  output reg [31:0]  spi_data,
  input wire [3:0] spi_I,
  output wire [3:0] spi_O,
  output wire spi_obuf_en,
  output reg spi_CS,
  output wire spi_clk
);

reg [31:0]  mem_addr;
//reg [7:0]   spi_cmd;

reg [4:0]   spi_cntr;

wire [7:0]   spi_cmd = 8'hEB;

reg addr_mux_0, addr_mux_1, addr_mux_2, addr_mux_3;

// FSM as a counter
always @ (negedge clk)
  if(ctrl_spi_start)
    spi_cntr <= 5'b11111;
  else
    if(spi_cntr != 5'd28)
      spi_cntr <= spi_cntr + 1'b1;

//always @ (posedge clk)
//  if(ctrl_addr_wr)
//    mem_addr <= ahb_addr;

always @ (posedge clk or negedge reset)
    if(!reset) spi_CS <= 1'b1;
    else if(ctrl_spi_start) spi_CS <= 1'b0;
    else if(spi_cntr == 5'd28) spi_CS <= 1'b1;
    
always @ *
  case (spi_cntr)
    5'd8: addr_mux_0 = ahb_addr[20];
    5'd9: addr_mux_0 = ahb_addr[16];
    5'd10: addr_mux_0 = ahb_addr[12];
    5'd11: addr_mux_0 = ahb_addr[8];
    5'd12: addr_mux_0 = ahb_addr[4];
    5'd13: addr_mux_0 = ahb_addr[0];
    default: addr_mux_0 = 1'b0;
  endcase

always @ *
  case (spi_cntr)
    5'd8: addr_mux_1 = ahb_addr[21];
    5'd9: addr_mux_1 = ahb_addr[17];
    5'd10: addr_mux_1 = ahb_addr[13];
    5'd11: addr_mux_1 = ahb_addr[9];
    5'd12: addr_mux_1 = ahb_addr[5];
    5'd13: addr_mux_1 = ahb_addr[1];
    default: addr_mux_1 = 1'b0;
  endcase

always @ *
  case (spi_cntr)
    5'd8: addr_mux_2 = ahb_addr[22];
    5'd9: addr_mux_2 = ahb_addr[18];
    5'd10: addr_mux_2 = ahb_addr[14];
    5'd11: addr_mux_2 = ahb_addr[10];
    5'd12: addr_mux_2 = ahb_addr[6];
    5'd13: addr_mux_2 = ahb_addr[2];
    default: addr_mux_2 = 1'b0;
  endcase

always @ *
  case (spi_cntr)
    5'd8: addr_mux_3 = ahb_addr[23];
    5'd9: addr_mux_3 = ahb_addr[19];
    5'd10: addr_mux_3 = ahb_addr[15];
    5'd11: addr_mux_3 = ahb_addr[11];
    5'd12: addr_mux_3 = ahb_addr[7];
    5'd13: addr_mux_3 = ahb_addr[3];
    default: addr_mux_3 = 1'b0;
  endcase


assign spi_O[0] = (spi_cntr[4:3] == 2'b00) ? spi_cmd[7-spi_cntr] : addr_mux_0;
assign spi_O[1] = (spi_cntr[4:3] == 2'b00) ? 1'b0 : addr_mux_1;
assign spi_O[2] = (spi_cntr[4:3] == 2'b00) ? 1'b0 : addr_mux_2;
assign spi_O[3] = (spi_cntr[4:3] == 2'b00) ? 1'b0 : addr_mux_3;

assign spi_obuf_en = ~spi_cntr[4];//(spi_cntr[4:2] != 3'b101) & (spi_cntr[4:2] != 3'b110);

assign spi_clk = clk | spi_CS;

always @ (posedge clk or negedge reset)
    if(!reset) spi_data <= 32'd0;
    else if((spi_cntr[4:2] == 3'b101) || (spi_cntr[4:2] == 3'b110))
        spi_data <= {spi_I,spi_data[31:4]};
    
endmodule
