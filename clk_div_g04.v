module clk_div (
    // Outputs
    clk_fst,
    // Inputs
    clk, rst
);

output reg clk_fst;     // 500 Hz clock (for 7-segment display) 

input       clk;
input       rst;

reg [16:0] fst;

parameter dividerf = 17'd100000;

always @ (posedge clk)
begin 
	if(rst)
	begin
		fst <= 17'd0;
		clk_fst <= 1'b0;
	end
	
	else
	begin
		if(fst == (dividerf - 1))
		begin
			fst <= 17'd0;
			clk_fst <= ~clk_fst;
		end
		else		
		begin
			fst <= fst + 1;
			clk_fst <= clk_fst;    //optional
		end
	end
end

endmodule // clk_div