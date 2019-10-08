
/*******************************************************************
 *
 * Module: APBGPIO.v
 * Project: Raptor
 * Author: mshalan
 * Description: APB 16-bit bi-directional GPIO with EN, PU and PD support
 *
 **********************************************************************/

module APBGPIO (
    //APB Inputs
    input wire PCLK,
    input wire PRESETn,
    input wire PWRITE,
    input wire [31:0] PWDATA,
    input wire [31:0] PADDR,
    input wire PENABLE,

    input PSEL,

    //APB Outputs
    output wire PREADY,
    output wire [31:0] PRDATA,

    // GPIO Ports
    input wire [15:0] GPIOIN,
    output wire [15:0] GPIOOUT,
    output wire [15:0] GPIOPU,
    output wire [15:0] GPIOPD,
    output wire [15:0] GPIOEN
);


  reg [15:0] gpio_data, gpio_data_next;   // Address 0: Port Data
  reg [15:0] gpio_dir;                    // Address 4: Port direction; 1:i/p, 0:o/p
  reg [15:0] gpio_pu, gpio_pd;			      // PU (Address: 8) & PD (Address: 16) enable registers @ 8 and 16 respectively


  assign GPIOEN = gpio_dir;
  assign GPIOPU = gpio_pu;
  assign GPIOPD = gpio_pd;
  assign GPIOOUT = gpio_data;
  
  assign PREADY = 1'b1; //always ready

  // The GPIO Direction Register (0: o/p, 1: i/p)
  always @(posedge PCLK, negedge PRESETn)
  begin
    if(!PRESETn)
    begin
      gpio_dir <= 16'b0;
    end
    else if(PENABLE & PWRITE & PREADY & PSEL & PADDR[2]) //
      gpio_dir <= PWDATA[15:0];
  end


  // The GPIO PU Register
  always @(posedge PCLK, negedge PRESETn)
  begin
    if(!PRESETn)
    begin
      gpio_pu <= 16'b0;
    end
    else if(PENABLE & PWRITE & PREADY & PSEL & PADDR[3]) //
      gpio_pu <= PWDATA[15:0];
  end

  // The GPIO PD Register
  always @(posedge PCLK, negedge PRESETn)
  begin
    if(!PRESETn)
    begin
      gpio_pd <= 16'b0;
    end
    else if(PENABLE & PWRITE & PREADY & PSEL & PADDR[4]) //
      gpio_pd <= PWDATA[15:0];
  end

  // The GPIO Data
  always @(posedge PCLK, negedge PRESETn)
  begin
      if(!PRESETn)
      begin
        gpio_data <= 16'b0;
      end
      else
        gpio_data <= gpio_data_next;
  end

    integer i;
    always @*
    begin
        for(i=0;i<16;i=i+1)
        begin
          if(gpio_dir[i] == 1'b1)
            gpio_data_next[i] = GPIOIN[i];
          else if(PENABLE & PWRITE & PREADY & PSEL & ~PADDR[2])
            gpio_data_next[i] = PWDATA[i];
          else
            gpio_data_next[i] = gpio_data[i];
        end
    end


    assign PRDATA[31:0] = (~PADDR[2]) ? {16'h0, gpio_data} : {16'h0, gpio_dir};

endmodule
