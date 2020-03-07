`timescale 1ns / 1ps

module uart_tb;
`include "game_definitions_g04.v"
`include "uart_state_definitions_g04.v"

   wire                   o_tx; // asynchronous UART TX
   reg                    i_rx; // asynchronous UART RX
   
   wire                   o_tx_busy;
   wire [7:0]             o_rx_data;
   wire                   o_rx_valid;
   
   reg [total_size-1:0]   i_tx_data;
   reg                    i_tx_stb;
   
   reg                    clk;
   reg                    rst;
   
   initial
	begin
		#10 rst = 1'b1;
		#10 clk = 1'b0;
		#10 rst = 1'b0;
		
		i_rx = 0;
		i_tx_stb = 1;
		#10000 i_tx_data [total_size-1:0] = {144'd0, 12'd256, 36'd0};
	end
	
	always
	begin
		#5 clk = ~clk;
	end
   
	uart_top uart_top_ (/*AUTOARG*/
	   // Outputs
	   .o_tx(o_tx), .o_tx_busy(o_tx_busy), .o_rx_data(o_rx_data), .o_rx_valid(o_rx_valid),
	   // Inputs
	   .i_rx(i_rx), .i_tx_data(i_tx_data), .i_tx_stb(i_tx_stb), .clk(clk), .rst(rst)
	   );
   
endmodule 