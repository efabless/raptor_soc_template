// file: clkmux.v
// author: @shalan

`timescale 1ns/1ns

module clkmux_2x1(clk1, clk2, clko, sel, rst);
   input clk1, clk2;
   input sel;
   output clko;
   input rst;

   reg Q1a, Q1b, Q2a, Q2b;
   wire q1a_in, q2a_in;

   assign clko = (clk1 & Q1b) | (clk2 & Q2b);

   wire  Q2b_bar = ~Q2b;
   wire  Q1b_bar = ~Q1b;
   wire  sel_bar = ~sel;

   assign q1a_in = Q2b_bar & sel_bar;
   assign q2a_in = Q1b_bar & sel;

   always @(posedge clk1 or posedge rst)
       if (rst) Q1a <= 1'b0; else
       Q1a <= q1a_in;

   always @(negedge clk1 or posedge rst)
       if (rst) Q1b <= 1'b0; else
       Q1b <= Q1a;

   always @(posedge clk2 or posedge rst)
       if (rst) Q2a <= 1'b0; else
       Q2a <= q2a_in;

   always @(negedge clk2 or posedge rst)
       if (rst) Q2b <= 1'b0; else
       Q2b <= Q2a;

endmodule


module clkmux_4x1(clk1, clk2, clk3, clk4, clko, sel, rst);
    input clk1, clk2, clk3, clk4, rst;
    input [1:0] sel;
    output clko;

    wire clko1, clko2;

    clkmux_2x1 m1(  .clk1(clk1), 
                    .clk2(clk2), 
                    .clko(clko1), 
                    .sel(sel[0]),
                    .rst(rst)
                );
    clkmux_2x1 m2(  .clk1(clk3), 
                    .clk2(clk4), 
                    .clko(clko2), 
                    .sel(sel[0]),
                    .rst(rst)
                );
    clkmux_2x1 m3(  .clk1(clko1), 
                    .clk2(clko2), 
                    .clko(clko), 
                    .sel(sel[1]),
                    .rst(rst)
                );
    
endmodule

module clkdiv (clk, rst, div, clko);
    input clk;
    input rst;
    input [1:0] div;
    output clko;

    reg [3:0]  divider;
    wire [3:0] ndivider;

    assign ndivider = divider + 1'd1;

    always @ (posedge clk or posedge rst) 
        if(rst) divider <= 4'd0;
        else divider <= ndivider;

    clkmux_4x1 m(.clk1(divider[0]), .clk2(divider[1]), .clk3(divider[2]), .clk4(divider[3]), .clko(clko), .sel(div), .rst(rst));

endmodule

/* This module exists inside the DC */
module clk_ctrl (
    input wire rst,           // SoC rst_lv
    input wire clk_hsi,       // SoC clk_hsi_lv
    input wire clk_hse,       // SoC clk_hse_lv
    input wire clk_pll_in,    // pll_clk
    output wire clk,          // system master clock
    output wire clk_pll_out,  // SoC clk_pll_src
    input wire [1:0] plldiv,  // from I/O Register
    input wire  pllbypass,    // from I/O Register
    input wire  pllsrc,       // from I/O Register
    input wire  hsisel,       // from I/O Register
    input wire  divbypass     // from I/O Register
);

    wire clk1, clk2, clk3;


    clkdiv CLK_DIV (
        .clk(clk_pll_in),
        .rst(rst),
        .div(plldiv),
        .clko(clk1)
    );

    clkmux_2x1 PllSrcMux (
         .clk1(clk_hsi),
         .clk2(clk_hse),
         .sel(pllsrc),
         .rst(rst),
         .clko(clk_pll_out)
    );

    clkmux_2x1 DIVByPassMux (
         .clk1(clk_pll_in),
         .clk2(clk1),
         .sel(divbypass),
       .rst(rst),
         .clko(clk2)
    );    
    
    clkmux_2x1 PllByPassMux (
         .clk1(clk_hse),
         .clk2(clk2),
         .sel(pllbypass),
       .rst(rst),
         .clko(clk3)
    );
     
    clkmux_2x1 HSIMux (
         .clk1(clk_hsi),
         .clk2(clk3),
         .sel(hsisel),
       .rst(rst),
         .clko(clk)
    );    
endmodule

/*
    PLLCR.0 to pll_cp_ena_lv
    PLLCR.1 to clk_ctrl.pplsrc
    PLLCR.3-2 to clk_ctrl.plldiv

    (PLLTR.0 | PLLCR.0) to pll_vco_ena_lv
    PLLTR.4-1 to pll_trim

    PLLSR.0 to pplsrc
    PLLSR.1 to pplbypass
    PLLSR.2 to divbypass
    PLLSR.3 to hsisel
    
*/

module AHBCLKCTRL(
    input wire HSEL,

    input wire HCLK,
    input wire HRESETn,
    
    input wire HREADY,
    input wire [31:0] HADDR,
    input wire [1:0] HTRANS,
    input wire HWRITE,
    input wire [31:0] HWDATA,
    
    output wire HREADYOUT,
    output wire [31:0] HRDATA,

    output wire [31:0] PLLCR,
    output wire [31:0] PLLTR,
    output wire [31:0] CLKCR
    
  );
  
  localparam [7:0] pllcr_addr = 8'h00;
  localparam [7:0] plltr_addr = 8'h04;
  localparam [7:0] clkcr_addr = 8'h08;
  

  reg [31:0] pllcr_data, plltr_data, clkcr_data;
  
  //reg [31:0] gpio_data_next;
  reg [31:0] last_HADDR;
  reg [1:0] last_HTRANS;
  reg last_HWRITE;
  reg last_HSEL;
  
  //reg [31:0] timeout_COUNTER;
  
  integer i;
  
  assign HREADYOUT = 1'b1;
  

  always @(posedge HCLK)
  begin
    if(HREADY)
    begin
      last_HADDR <= HADDR;
      last_HTRANS <= HTRANS;
      last_HWRITE <= HWRITE;
      last_HSEL <= HSEL;
    end
  end
  
  always @(posedge HCLK, negedge HRESETn)
  begin
    if(!HRESETn)
      pllcr_data <= 32'h0;
    else
      if((last_HADDR[7:0] == pllcr_addr) & last_HSEL & last_HWRITE & last_HTRANS[1])
        pllcr_data <= HWDATA;  
  end

  always @(posedge HCLK, negedge HRESETn)
  begin
    if(!HRESETn)
      plltr_data <= 32'h0;
    else
      if((last_HADDR[7:0] == plltr_addr) & last_HSEL & last_HWRITE & last_HTRANS[1])
        plltr_data <= HWDATA;  
  end

  always @(posedge HCLK, negedge HRESETn)
  begin
    if(!HRESETn)
      clkcr_data <= 32'h0;
    else
      if((last_HADDR[7:0] == clkcr_addr) & last_HSEL & last_HWRITE & last_HTRANS[1])
        clkcr_data <= HWDATA;  
  end  


  assign HRDATA[31:0] = (last_HADDR[7:0] == pllcr_addr) ? pllcr_data :  
                        (last_HADDR[7:0] == plltr_addr) ? plltr_data : 
                        clkcr_data;

  assign PLLCR = pllcr_data;
  assign PLLTR = plltr_data;
  assign CLKCR = clkcr_data;
  
endmodule

