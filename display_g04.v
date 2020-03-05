module display_controller (
    // Outputs
    AN, SEG,
    // Inputs
    clk_500hz, rst, value
);

input   clk_500hz;
input   rst;
input   [11:0]  value;

output reg [3:0] AN;
output reg [6:0] SEG;

reg [1:0] LED_counter;


function [6:0] fnmaxsel2seg;
    input [11:0] num;
	input [1:0] pos;
    begin
		case(pos)
		2'b00:		// ones
		begin
			case(num)
			12'd2048: fnmaxsel2seg = 7'b0000000;
			12'd1024: fnmaxsel2seg = 7'b0011001;
			12'd512: fnmaxsel2seg = 7'b0100100;
			12'd256: fnmaxsel2seg = 7'b0000010;
			12'd128: fnmaxsel2seg = 7'b0000000;
			12'd64: fnmaxsel2seg = 7'b0011001;
			12'd32: fnmaxsel2seg = 7'b0100100;	
			12'd16: fnmaxsel2seg = 7'b0000010;
			12'd8: fnmaxsel2seg = 7'b0000000;
			12'd4: fnmaxsel2seg = 7'b0011001;
			12'd2: fnmaxsel2seg = 7'b0100100;
			default: fnmaxsel2seg = 7'b0000110;    // E
			endcase
		end
		
        2'b01:		// tens 
		begin
			case(num)
			12'd2048: fnmaxsel2seg = 7'b0011001;
			12'd1024: fnmaxsel2seg = 7'b0100100;
			12'd512: fnmaxsel2seg = 7'b1111001;
			12'd256: fnmaxsel2seg = 7'b0010010;
			12'd128: fnmaxsel2seg = 7'b0100100;
			12'd64: fnmaxsel2seg = 7'b0000010;
			12'd32: fnmaxsel2seg = 7'b0110000;
			12'd16: fnmaxsel2seg = 7'b1111001; 
			12'd8: fnmaxsel2seg = 7'b1111111;     //nothing
			12'd4: fnmaxsel2seg = 7'b1111111;
			12'd2: fnmaxsel2seg = 7'b1111111;
			default: fnmaxsel2seg = 7'b0010010;    // S
			endcase
		end
		
        2'b10:		// hundreds
		begin
			case(num)
			12'd2048: fnmaxsel2seg = 7'b1000000; 
			12'd1024: fnmaxsel2seg = 7'b1000000; 
			12'd512: fnmaxsel2seg = 7'b0010010;
			12'd256: fnmaxsel2seg = 7'b0100100;
			12'd128: fnmaxsel2seg = 7'b1111001; 
			12'd64: fnmaxsel2seg = 7'b1111111;    //nothing
			12'd32: fnmaxsel2seg = 7'b1111111;
			12'd16: fnmaxsel2seg = 7'b1111111;
			12'd8: fnmaxsel2seg = 7'b1111111;
			12'd4: fnmaxsel2seg = 7'b1111111;
			12'd2: fnmaxsel2seg = 7'b1111111;
			default: fnmaxsel2seg = 7'b1000000;    // O
			endcase
		end
		
        2'b11:		// thousands
		begin
			case(num)
			12'd2048: fnmaxsel2seg = 7'b0100100;
			12'd1024: fnmaxsel2seg = 7'b1111001; 
			12'd512: fnmaxsel2seg = 7'b1111111;   //nothing
			12'd256: fnmaxsel2seg = 7'b1111111;
			12'd128: fnmaxsel2seg = 7'b1111111;
			12'd64: fnmaxsel2seg = 7'b1111111;
			12'd32: fnmaxsel2seg = 7'b1111111;
			12'd16: fnmaxsel2seg = 7'b1111111;
			12'd8: fnmaxsel2seg = 7'b1111111;
			12'd4: fnmaxsel2seg = 7'b1111111;
			12'd2: fnmaxsel2seg = 7'b1111111;
			default: fnmaxsel2seg = 7'b1000111;    // L
			endcase
		end
		endcase
		
    end
endfunction


function [3:0] fncounter2an;
    input [1:0] counter;
    begin
        case(counter)
        2'b00: fncounter2an = 4'b1110;     //right most
        2'b01: fncounter2an = 4'b1101;
        2'b10: fncounter2an = 4'b1011;
        2'b11: fncounter2an = 4'b0111;
        endcase
    end
endfunction


always @(posedge clk_500hz)
begin
    if(rst)
        LED_counter [1:0] <= 0;
    else 
        LED_counter <= LED_counter + 1;
end


always @(*)
begin
	AN [3:0] = fncounter2an(LED_counter[1:0]);
	SEG [6:0] = fnmaxsel2seg((value), (LED_counter[1:0]));
end


endmodule   //display_controller