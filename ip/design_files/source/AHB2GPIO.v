/*******************************************************************
 *
 * Module: AHB2GPIO.v
 * Project: Raptor
 * Author: mshalan
 * Description: AHB 16-bit bi-directional GPIO with EN, PU and PD support
 *
 **********************************************************************/

module AHB2GPIO (
	input wire 			HCLK,
	input wire 			HRESETn,
	input wire [31:0] 	HADDR,
	input wire [1:0] 	HTRANS,
	input wire [31:0] 	HWDATA,
	input wire 			HWRITE,
		input wire 			HSEL,
		input wire 			HREADY,
	
	output wire 		HREADYOUT,
	output wire 		[31:0] HRDATA,

		// GPIO Ports
		input 	wire [15:0] GPIOIN,
		output 	wire [15:0] GPIOOUT,
		output 	wire [15:0] GPIOPU,
		output 	wire [15:0] GPIOPD,
		output 	wire [15:0] GPIOEN
		
	);

	reg [15:0] gpio_data, gpio_data_next;   // Address 0: Port Data
		reg [15:0] gpio_dir;                    // Address 4: Port direction; 1:i/p, 0:o/p
		reg [15:0] gpio_pu, gpio_pd;	        // PU (Address: 8) & PD (Address: 16) enable registers @ 8 and 16 respectively


		assign GPIOEN 	= gpio_dir;
		assign GPIOPU 	= gpio_pu;
		assign GPIOPD 	= gpio_pd;
		assign GPIOOUT 	= gpio_data;
	
		assign HREADYOUT = 1'b1;

		reg [31:0] 	last_HADDR;
		reg [1:0] 	last_HTRANS;
		reg 		last_HWRITE;
		reg 		last_HSEL;
	
		always @(posedge HCLK) begin
			if(HREADY) begin
					last_HADDR <= HADDR;
					last_HTRANS <= HTRANS;
					last_HWRITE <= HWRITE;
					last_HSEL <= HSEL;
			end
		end
	

		// The GPIO Direction Register (0: o/p, 1: i/p)
		always @(posedge HCLK, negedge HRESETn)
		begin
			if(!HRESETn)
					gpio_dir <= 16'b0;
			else if((last_HADDR[2]) & last_HSEL & last_HWRITE & last_HTRANS[1])
					gpio_dir <= HWDATA[15:0];
		end


		// The GPIO PU Register
		always @(posedge HCLK, negedge HRESETn)
		begin
			if(!HRESETn)
					gpio_pu <= 16'b0;
			else if((last_HADDR[3]) & last_HSEL & last_HWRITE & last_HTRANS[1])
					gpio_pu <= HWDATA[15:0];
		end


		// The GPIO PD Register
		always @(posedge HCLK, negedge HRESETn)
		begin
			if(!HRESETn)
					gpio_pd <= 16'b0;
			else if((last_HADDR[4]) & last_HSEL & last_HWRITE & last_HTRANS[1])
					gpio_pd <= HWDATA[15:0];
		end
	
		// The GPIO Data
	always @(posedge HCLK, negedge HRESETn)
		begin
			if(!HRESETn)
					gpio_data <= 16'b0;
			else if((last_HADDR[7:0]==8'd0) & last_HSEL & last_HWRITE & last_HTRANS[1])
					gpio_data <= gpio_data_next;
		end
		
	integer i;
		always @*
		begin
				for(i=0;i<16;i=i+1)
				begin
					if(gpio_dir[i] == 1'b1)
						gpio_data_next[i] = GPIOIN[i];
					else if((last_HADDR[7:0]==8'd0) & last_HSEL & last_HWRITE & last_HTRANS[1])
						gpio_data_next[i] = HWDATA[i];
					else
						gpio_data_next[i] = gpio_data[i];
				end
		end
		
		assign HRDATA[31:0] = (~last_HADDR[2]) ? {16'h0, GPIOIN} : {16'h0, gpio_dir};

endmodule