module uart_top (/*AUTOARG*/
   // Outputs
   o_tx, o_tx_busy, o_rx_data, o_rx_valid,
   // Inputs
   i_rx, i_tx_data, i_tx_stb, clk, rst
   );

`include "game_definitions_g04.v"
`include "uart_state_definitions_g04.v"

   output                   o_tx; // asynchronous UART TX
   input                    i_rx; // asynchronous UART RX
   
   output                   o_tx_busy;
   output [7:0]             o_rx_data;
   output                   o_rx_valid;
   
   input [total_size-1:0]   i_tx_data;
   input                    i_tx_stb;
   
   input                    clk;
   input                    rst;

   
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire                 tfifo_empty;            // From tfifo_ of uart_fifo.v
   wire                 tfifo_full;             // From tfifo_ of uart_fifo.v
   wire [7:0]           tfifo_out;              // From tfifo_ of uart_fifo.v
   // End of automatics

   reg [7:0]            tfifo_in;
   wire                 tx_active;
   wire                 tfifo_rd;
   reg                  tfifo_rd_z;
   reg [total_size-1:0]  tx_data;
   
   // states 
   reg [3:0]        	top_state;   	 	// Output lines, one state per line, 15 states
   reg [4:0]  			line_state;   		// lines, 21 states


   assign o_tx_busy = (top_state!=stIdle);
	
	// State transitions
	always @ (posedge clk)
	begin 
		if(rst)
		begin
			top_state <= stIdle;
			line_state <= stField1_1;
		end
		else
		begin
			case (top_state)
			stIdle:
				if (i_tx_stb)
				begin
					top_state <= stClear1;
					tx_data <= i_tx_data;
				end
			stData1:
				if (~tfifo_full)
				begin
					case (line_state)
					stCR:
						begin
							top_state <= stLine1;
							line_state <= stField1_1;
						end 
					default: 
						begin
							top_state <= top_state;
							line_state <= line_state + 1;
						end
					endcase    // case (line_state)
				end
			stLine1:
				if (~tfifo_full)
				begin
					case (line_state)
					stCR:
						begin
							top_state <= stData2;
							line_state <= stField1_1;
						end 
					default: 
						begin
							top_state <= top_state;
							line_state <= line_state + 1;
						end
					endcase    // case (line_state)
				end
			stData2:
				if (~tfifo_full)
				begin
					case (line_state)
					stCR:
						begin
							top_state <= stLine2;
							line_state <= stField1_1;
						end 
					default: 
						begin
							top_state <= top_state;
							line_state <= line_state + 1;
						end
					endcase    // case (line_state)
				end
			stLine2:
				if (~tfifo_full)
				begin
					case (line_state)
					stCR:
						begin
							top_state <= stData3;
							line_state <= stField1_1;
						end 
					default: 
						begin
							top_state <= top_state;
							line_state <= line_state + 1;
						end
					endcase    // case (line_state)
				end
			stData3:
				if (~tfifo_full)
				begin
					case (line_state)
					stCR:
						begin
							top_state <= stLine3;
							line_state <= stField1_1;
						end 
					default: 
						begin
							top_state <= top_state;
							line_state <= line_state + 1;
						end
					endcase    // case (line_state)
				end
			stLine3:
				if (~tfifo_full)
				begin
					case (line_state)
					stCR:
						begin
							top_state <= stData4;
							line_state <= stField1_1;
						end 
					default: 
						begin
							top_state <= top_state;
							line_state <= line_state + 1;
						end
					endcase    // case (line_state)
				end
			stData4:
				if (~tfifo_full)
				begin
					case (line_state)
					stCR:
						begin
							top_state <= stLine4;
							line_state <= stField1_1;
						end 
					default: 
						begin
							top_state <= top_state;
							line_state <= line_state + 1;
						end
					endcase    // case (line_state)
				end
			stLine4:
				if (~tfifo_full)
				begin
					case (line_state)
					stCR:
						begin
							top_state <= stIdle;
							line_state <= stField1_1;
						end 
					default: 
						begin
							top_state <= top_state;
							line_state <= line_state + 1;
						end
					endcase    // case (line_state)
				end
			default:     // stClear1 - stClear7
				if (~tfifo_full)
					top_state <= top_state + 1;
			endcase   // case (top_state)
		end
	end 
	
	
	function [7:0] fnBlockPos2ASCII;
		input [block_size-1:0] num;    // number stored in block 
		input [1:0]  pos;    // desired field position in four digits 
		begin
			case (pos)
			2'd0:    // left most character 
				case (num)
				12'd2048: fnBlockPos2ASCII = "2";
				12'd1024: fnBlockPos2ASCII = "1";
				//12'd512: fnBlockPos2ASCII = " ";
				//12'd256: fnBlockPos2ASCII = " ";
				//12'd128: fnBlockPos2ASCII = " ";
				//12'd64: fnBlockPos2ASCII = " ";
				//12'd32: fnBlockPos2ASCII = " ";
				//12'd16: fnBlockPos2ASCII = " ";
				//12'd8: fnBlockPos2ASCII = " ";
				//12'd4: fnBlockPos2ASCII = " ";
				//12'd2: fnBlockPos2ASCII = " ";
				default: fnBlockPos2ASCII = " ";
				endcase  // case(num)
			2'd1:
				case (num)
				12'd2048: fnBlockPos2ASCII = "0";
				12'd1024: fnBlockPos2ASCII = "0";
				12'd512: fnBlockPos2ASCII = "5";
				12'd256: fnBlockPos2ASCII = "2";
				12'd128: fnBlockPos2ASCII = "1";
				12'd64: fnBlockPos2ASCII = "6";
				12'd32: fnBlockPos2ASCII = "3";
				12'd16: fnBlockPos2ASCII = "1";
				//12'd8: fnBlockPos2ASCII = " ";
				//12'd4: fnBlockPos2ASCII = " ";
				//12'd2: fnBlockPos2ASCII = " ";
				default: fnBlockPos2ASCII = " ";
				endcase  // case(num)
			2'd2:
				case (num)
				12'd2048: fnBlockPos2ASCII = "4";
				12'd1024: fnBlockPos2ASCII = "2";
				12'd512: fnBlockPos2ASCII = "1";
				12'd256: fnBlockPos2ASCII = "5";
				12'd128: fnBlockPos2ASCII = "2";
				12'd64: fnBlockPos2ASCII = "4";
				12'd32: fnBlockPos2ASCII = "2";
				12'd16: fnBlockPos2ASCII = "6";
				12'd8: fnBlockPos2ASCII = "8";
				12'd4: fnBlockPos2ASCII = "4";
				12'd2: fnBlockPos2ASCII = "2";
				default: fnBlockPos2ASCII = " ";
				endcase  // case(num)
			2'd3:
				case (num)
				12'd2048: fnBlockPos2ASCII = "8";
				12'd1024: fnBlockPos2ASCII = "4";
				12'd512: fnBlockPos2ASCII = "2";
				12'd256: fnBlockPos2ASCII = "6";
				12'd128: fnBlockPos2ASCII = "8";
				//12'd64: fnBlockPos2ASCII = " ";
				//12'd32: fnBlockPos2ASCII = " ";
				//12'd16: fnBlockPos2ASCII = " ";
				//12'd8: fnBlockPos2ASCII = " ";
				//12'd4: fnBlockPos2ASCII = " ";
				//12'd2: fnBlockPos2ASCII = " ";
				default: fnBlockPos2ASCII = " ";
				endcase  // case(num)
			endcase  // case (pos)
		end
	endfunction
   
   
   // Output Assignment 
   always @(*)
   begin
	case(top_state)
		stIdle: 	tfifo_in = 0;    	// dummy 
		stClear1:	tfifo_in = 8'd27;	// ESC
		stClear2:	tfifo_in = "[";
		stClear3:	tfifo_in = "2";
		stClear4:	tfifo_in = "J";
		stClear5:	tfifo_in = 8'd27;	// cursor home 
		stClear6:	tfifo_in = "[";
		stClear7:	tfifo_in = "H";
		stData1:
			case (line_state)
				stField1_1:		tfifo_in = fnBlockPos2ASCII( (tx_data[b1_start:b1_end]), (2'd0));
				stField1_2:		tfifo_in = fnBlockPos2ASCII( (tx_data[b1_start:b1_end]), (2'd1));
				stField1_3:		tfifo_in = fnBlockPos2ASCII( (tx_data[b1_start:b1_end]), (2'd2));
				stField1_4:		tfifo_in = fnBlockPos2ASCII( (tx_data[b1_start:b1_end]), (2'd3));
				stSep1:			tfifo_in = "|";
				stField2_1:		tfifo_in = fnBlockPos2ASCII( (tx_data[b2_start:b2_end]), (2'd0));
				stField2_2:		tfifo_in = fnBlockPos2ASCII( (tx_data[b2_start:b2_end]), (2'd1));
				stField2_3:		tfifo_in = fnBlockPos2ASCII( (tx_data[b2_start:b2_end]), (2'd2));
				stField2_4:		tfifo_in = fnBlockPos2ASCII( (tx_data[b2_start:b2_end]), (2'd3));
				stSep2:			tfifo_in = "|";
				stField3_1:		tfifo_in = fnBlockPos2ASCII( (tx_data[b3_start:b3_end]), (2'd0));
				stField3_2:		tfifo_in = fnBlockPos2ASCII( (tx_data[b3_start:b3_end]), (2'd1));
				stField3_3:		tfifo_in = fnBlockPos2ASCII( (tx_data[b3_start:b3_end]), (2'd2));
				stField3_4:		tfifo_in = fnBlockPos2ASCII( (tx_data[b3_start:b3_end]), (2'd3));
				stSep3:			tfifo_in = "|";
				stField4_1:		tfifo_in = fnBlockPos2ASCII( (tx_data[b4_start:b4_end]), (2'd0));
				stField4_2:		tfifo_in = fnBlockPos2ASCII( (tx_data[b4_start:b4_end]), (2'd1));
				stField4_3:		tfifo_in = fnBlockPos2ASCII( (tx_data[b4_start:b4_end]), (2'd2));
				stField4_4:		tfifo_in = fnBlockPos2ASCII( (tx_data[b4_start:b4_end]), (2'd3));
				stNL: 			tfifo_in = "\n";
				stCR:			tfifo_in = "\r";
			endcase   // case (line_state)
		stLine1:
			case (line_state)
				stField1_1:		tfifo_in = "-";
				stField1_2:		tfifo_in = "-";
				stField1_3:		tfifo_in = "-";
				stField1_4:		tfifo_in = "-";
				stSep1:			tfifo_in = "+";
				stField2_1:		tfifo_in = "-";
				stField2_2:		tfifo_in = "-";
				stField2_3:		tfifo_in = "-";
				stField2_4:		tfifo_in = "-";
				stSep2:			tfifo_in = "+";
				stField3_1:		tfifo_in = "-";
				stField3_2:		tfifo_in = "-";
				stField3_3:		tfifo_in = "-";
				stField3_4:		tfifo_in = "-";
				stSep3:			tfifo_in = "+";
				stField4_1:		tfifo_in = "-";
				stField4_2:		tfifo_in = "-";
				stField4_3:		tfifo_in = "-";
				stField4_4:		tfifo_in = "-";
				stNL: 			tfifo_in = "\n";
				stCR:			tfifo_in = "\r";
			endcase   // case (line_state)
		stData2:
			case (line_state)
				stField1_1:		tfifo_in = fnBlockPos2ASCII( (tx_data[b5_start:b5_end]), (2'd0));
				stField1_2:		tfifo_in = fnBlockPos2ASCII( (tx_data[b5_start:b5_end]), (2'd1));
				stField1_3:		tfifo_in = fnBlockPos2ASCII( (tx_data[b5_start:b5_end]), (2'd2));
				stField1_4:		tfifo_in = fnBlockPos2ASCII( (tx_data[b5_start:b5_end]), (2'd3));
				stSep1:			tfifo_in = "|";
				stField2_1:		tfifo_in = fnBlockPos2ASCII( (tx_data[b6_start:b6_end]), (2'd0));
				stField2_2:		tfifo_in = fnBlockPos2ASCII( (tx_data[b6_start:b6_end]), (2'd1));
				stField2_3:		tfifo_in = fnBlockPos2ASCII( (tx_data[b6_start:b6_end]), (2'd2));
				stField2_4:		tfifo_in = fnBlockPos2ASCII( (tx_data[b6_start:b6_end]), (2'd3));
				stSep2:			tfifo_in = "|";
				stField3_1:		tfifo_in = fnBlockPos2ASCII( (tx_data[b7_start:b7_end]), (2'd0));
				stField3_2:		tfifo_in = fnBlockPos2ASCII( (tx_data[b7_start:b7_end]), (2'd1));
				stField3_3:		tfifo_in = fnBlockPos2ASCII( (tx_data[b7_start:b7_end]), (2'd2));
				stField3_4:		tfifo_in = fnBlockPos2ASCII( (tx_data[b7_start:b7_end]), (2'd3));
				stSep3:			tfifo_in = "|";
				stField4_1:		tfifo_in = fnBlockPos2ASCII( (tx_data[b8_start:b8_end]), (2'd0));
				stField4_2:		tfifo_in = fnBlockPos2ASCII( (tx_data[b8_start:b8_end]), (2'd1));
				stField4_3:		tfifo_in = fnBlockPos2ASCII( (tx_data[b8_start:b8_end]), (2'd2));
				stField4_4:		tfifo_in = fnBlockPos2ASCII( (tx_data[b8_start:b8_end]), (2'd3));
				stNL: 			tfifo_in = "\n";
				stCR:			tfifo_in = "\r";
			endcase   // case (line_state)
		stLine2:
			case (line_state)
				stField1_1:		tfifo_in = "-";
				stField1_2:		tfifo_in = "-";
				stField1_3:		tfifo_in = "-";
				stField1_4:		tfifo_in = "-";
				stSep1:			tfifo_in = "+";
				stField2_1:		tfifo_in = "-";
				stField2_2:		tfifo_in = "-";
				stField2_3:		tfifo_in = "-";
				stField2_4:		tfifo_in = "-";
				stSep2:			tfifo_in = "+";
				stField3_1:		tfifo_in = "-";
				stField3_2:		tfifo_in = "-";
				stField3_3:		tfifo_in = "-";
				stField3_4:		tfifo_in = "-";
				stSep3:			tfifo_in = "+";
				stField4_1:		tfifo_in = "-";
				stField4_2:		tfifo_in = "-";
				stField4_3:		tfifo_in = "-";
				stField4_4:		tfifo_in = "-";
				stNL: 			tfifo_in = "\n";
				stCR:			tfifo_in = "\r";
			endcase   // case (line_state)
		stData3:
			case (line_state)
				stField1_1:		tfifo_in = fnBlockPos2ASCII( (tx_data[b9_start:b9_end]), (2'd0));
				stField1_2:		tfifo_in = fnBlockPos2ASCII( (tx_data[b9_start:b9_end]), (2'd1));
				stField1_3:		tfifo_in = fnBlockPos2ASCII( (tx_data[b9_start:b9_end]), (2'd2));
				stField1_4:		tfifo_in = fnBlockPos2ASCII( (tx_data[b9_start:b9_end]), (2'd3));
				stSep1:			tfifo_in = "|";
				stField2_1:		tfifo_in = fnBlockPos2ASCII( (tx_data[b10_start:b10_end]), (2'd0));
				stField2_2:		tfifo_in = fnBlockPos2ASCII( (tx_data[b10_start:b10_end]), (2'd1));
				stField2_3:		tfifo_in = fnBlockPos2ASCII( (tx_data[b10_start:b10_end]), (2'd2));
				stField2_4:		tfifo_in = fnBlockPos2ASCII( (tx_data[b10_start:b10_end]), (2'd3));
				stSep2:			tfifo_in = "|";
				stField3_1:		tfifo_in = fnBlockPos2ASCII( (tx_data[b11_start:b11_end]), (2'd0));
				stField3_2:		tfifo_in = fnBlockPos2ASCII( (tx_data[b11_start:b11_end]), (2'd1));
				stField3_3:		tfifo_in = fnBlockPos2ASCII( (tx_data[b11_start:b11_end]), (2'd2));
				stField3_4:		tfifo_in = fnBlockPos2ASCII( (tx_data[b11_start:b11_end]), (2'd3));
				stSep3:			tfifo_in = "|";
				stField4_1:		tfifo_in = fnBlockPos2ASCII( (tx_data[b12_start:b12_end]), (2'd0));
				stField4_2:		tfifo_in = fnBlockPos2ASCII( (tx_data[b12_start:b12_end]), (2'd1));
				stField4_3:		tfifo_in = fnBlockPos2ASCII( (tx_data[b12_start:b12_end]), (2'd2));
				stField4_4:		tfifo_in = fnBlockPos2ASCII( (tx_data[b12_start:b12_end]), (2'd3));
				stNL: 			tfifo_in = "\n";
				stCR:			tfifo_in = "\r";
			endcase   // case (line_state)
		stLine3:
			case (line_state)
				stField1_1:		tfifo_in = "-";
				stField1_2:		tfifo_in = "-";
				stField1_3:		tfifo_in = "-";
				stField1_4:		tfifo_in = "-";
				stSep1:			tfifo_in = "+";
				stField2_1:		tfifo_in = "-";
				stField2_2:		tfifo_in = "-";
				stField2_3:		tfifo_in = "-";
				stField2_4:		tfifo_in = "-";
				stSep2:			tfifo_in = "+";
				stField3_1:		tfifo_in = "-";
				stField3_2:		tfifo_in = "-";
				stField3_3:		tfifo_in = "-";
				stField3_4:		tfifo_in = "-";
				stSep3:			tfifo_in = "+";
				stField4_1:		tfifo_in = "-";
				stField4_2:		tfifo_in = "-";
				stField4_3:		tfifo_in = "-";
				stField4_4:		tfifo_in = "-";
				stNL: 			tfifo_in = "\n";
				stCR:			tfifo_in = "\r";
			endcase   // case (line_state)
		stData4:
			case (line_state)
				stField1_1:		tfifo_in = fnBlockPos2ASCII( (tx_data[b13_start:b13_end]), (2'd0));
				stField1_2:		tfifo_in = fnBlockPos2ASCII( (tx_data[b13_start:b13_end]), (2'd1));
				stField1_3:		tfifo_in = fnBlockPos2ASCII( (tx_data[b13_start:b13_end]), (2'd2));
				stField1_4:		tfifo_in = fnBlockPos2ASCII( (tx_data[b13_start:b13_end]), (2'd3));
				stSep1:			tfifo_in = "|";
				stField2_1:		tfifo_in = fnBlockPos2ASCII( (tx_data[b14_start:b14_end]), (2'd0));
				stField2_2:		tfifo_in = fnBlockPos2ASCII( (tx_data[b14_start:b14_end]), (2'd1));
				stField2_3:		tfifo_in = fnBlockPos2ASCII( (tx_data[b14_start:b14_end]), (2'd2));
				stField2_4:		tfifo_in = fnBlockPos2ASCII( (tx_data[b14_start:b14_end]), (2'd3));
				stSep2:			tfifo_in = "|";
				stField3_1:		tfifo_in = fnBlockPos2ASCII( (tx_data[b15_start:b15_end]), (2'd0));
				stField3_2:		tfifo_in = fnBlockPos2ASCII( (tx_data[b15_start:b15_end]), (2'd1));
				stField3_3:		tfifo_in = fnBlockPos2ASCII( (tx_data[b15_start:b15_end]), (2'd2));
				stField3_4:		tfifo_in = fnBlockPos2ASCII( (tx_data[b15_start:b15_end]), (2'd3));
				stSep3:			tfifo_in = "|";
				stField4_1:		tfifo_in = fnBlockPos2ASCII( (tx_data[b16_start:b16_end]), (2'd0));
				stField4_2:		tfifo_in = fnBlockPos2ASCII( (tx_data[b16_start:b16_end]), (2'd1));
				stField4_3:		tfifo_in = fnBlockPos2ASCII( (tx_data[b16_start:b16_end]), (2'd2));
				stField4_4:		tfifo_in = fnBlockPos2ASCII( (tx_data[b16_start:b16_end]), (2'd3));
				stNL: 			tfifo_in = "\n";
				stCR:			tfifo_in = "\r";
			endcase   // case (line_state)
			
			stLine4: 
				//tfifo_in = "H";
				tfifo_in = "\0";
	endcase  // case (top_state)
   end
   
   
   assign tfifo_rd = ~tfifo_empty & ~tx_active & ~tfifo_rd_z;
   assign tfifo_wr = ~tfifo_full & (top_state!=stIdle);
   
   uart_fifo tfifo_ (// Outputs
                     .fifo_cnt          (),
                     .fifo_out          (tfifo_out[7:0]),
                     .fifo_full         (tfifo_full),
                     .fifo_empty        (tfifo_empty),
                     // Inputs
                     .fifo_in           (tfifo_in[7:0]),
                     .fifo_rd           (tfifo_rd),
                     .fifo_wr           (tfifo_wr),
                     /*AUTOINST*/
                     // Inputs
                     .clk               (clk),
                     .rst               (rst));

   always @ (posedge clk)
     if (rst)
       tfifo_rd_z <= 1'b0;
     else
       tfifo_rd_z <= tfifo_rd;

   uart uart_ (// Outputs
               .received                (o_rx_valid),
               .rx_byte                 (o_rx_data[7:0]),
               .is_receiving            (),
               .is_transmitting         (tx_active),
               .recv_error              (),
               .tx                      (o_tx),
               // Inputs
               .rx                      (i_rx),
               .transmit                (tfifo_rd_z),
               .tx_byte                 (tfifo_out[7:0]),
               /*AUTOINST*/
               // Inputs
               .clk                     (clk),
               .rst                     (rst));
   
endmodule // uart_top
// Local Variables:
// verilog-library-flags:("-y ../../osdvu/")
// End:
