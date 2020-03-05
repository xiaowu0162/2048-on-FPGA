module game_logic (
    // Input
    btnL, btnR, btnD, btnU, rst, clk, diff, i_tx_busy, i_valid,
    // Output
    data, max, o_valid
);

`include "game_definitions_g04.v"

input rst, btnL, btnR, btnU, btnD, clk, i_tx_busy, i_valid;
input [1:0] diff;

output reg [total_size-1:0] data;
output reg [block_size-1:0] max;
output o_valid;

// state machine
reg [1:0] state;
parameter S_init = 2'd0;
parameter S_merge = 2'd1;
parameter S_shift = 2'd2;
parameter S_gen = 2'd3;

reg win, lose, merge_success;
reg [15:0] bmap;   // data bitmap
reg [3:0]  ctrl;   // control  {U,D,L,R}

parameter first = 47;
parameter second = 35;
parameter third = 23;
parameter fourth = 11;


assign o_valid = i_valid & ~i_tx_busy;

reg new_clk_500hz;
reg [17:0] clk_500hz_counter;
parameter div_500hz = 18'd133333;

// 500hz clock divider 
always @ (posedge clk)
begin 
	if(rst)
	begin
		clk_500hz_counter <= 18'd0;
		new_clk_500hz <= 1'b0;
	end
	else if(clk_500hz_counter == 18'd66666)
	begin
		clk_500hz_counter <= clk_500hz_counter + 1;
		new_clk_500hz <= 1'b1;
	end
	else if(clk_500hz_counter == (div_500hz - 1))
	begin
		clk_500hz_counter <= 0;
		new_clk_500hz <= 1'b0;
	end
	else 
	begin 
		clk_500hz_counter <= clk_500hz_counter + 1;
		new_clk_500hz <= 1'b0;
	end 

end


// helper function: truncate 13-bit expression to 12 bits
function [11:0] trunc12;
	input [12:0] val13;
	begin
		trunc12 = val13[11:0];
	end
endfunction


//////////////////////
// Merging logic
//////////////////////
function [47:0] merge_action;
	input [47:0] num;
	begin
		if((num[first:second+1] == num[second:third+1]) && (num[third:fourth+1]==num[fourth:0]))  //1133
			merge_action[47:0] = {trunc12(num[first:second+1]*2), trunc12(num[third:fourth+1]*2), 24'b0}; 
		else if(num[first:second+1] == num[second:third+1])    //1134
			merge_action[47:0] = {trunc12(num[first:second+1]*2), num[third:fourth+1], num[fourth:0], 12'b0};
		else if((num[first:second+1] == num[third:fourth+1]) && (num[second:third+1] == 0))    //1014
			merge_action[47:0] = {trunc12(num[first:second+1]*2), num[fourth:0], 24'b0};
		else if((num[first:second+1] == num[fourth:0]) && (num[second:third+1] == 0) &&(num[third:fourth+1] == 0))  //1001
			merge_action[47:0] = {trunc12(num[first:second+1]*2), 36'b0};
		else if(num[second:third+1] == num[third:fourth+1])      //1224
			merge_action[47:0] = {num[first:second+1], trunc12(num[second:third+1]*2), num[fourth:0], 12'b0};
		else if((num[second:third+1] == num[fourth:0]) && (num[third:fourth+1] == 0))    //1202
			merge_action[47:0] = {num[first:second+1], trunc12(num[second:third+1]*2), 24'b0};
		else if(num[third:fourth+1] == num[fourth:0])    //1233
			merge_action[47:0] = {num[first:second+1], num[second:third+1], trunc12(num[third:fourth+1]*2), 12'b0};
		else   //1234
			merge_action[47:0] = num[47:0];
	end
endfunction


/////////////////////
// Shifting logic
////////////////////
function [51:0] shift_action;    // four bitmap bits + 44 data bits
	input [47:0] num;
	begin
        if (num[first:0] == 0)           //0000
            shift_action = {4'b0000, num[first:0]};
            
        else if(num[second:0] == 0)      //1000           //(num[first:second+1] != 0 && num[second:0] == 0)
            shift_action = {4'b1000, num[first:0]};
        else if(num[first:second+1] == 0  && num[second:third+1] != 0 && num[third:0] == 0)     //0100
            shift_action = {4'b1000, num[second:0], num[first:second+1]};
        else if(num[first:third+1] == 0  && num[third:fourth+1] != 0 && num[fourth:0] == 0)     //0010
            shift_action = {4'b1000, num[third:0], num[first:third+1]};
        else if(num[first:fourth+1] == 0)    //0001
            shift_action = {4'b1000, num[fourth:0], num[first:fourth+1]};
            
        else if(num[first:second+1] != 0 && num[second:third+1] != 0 && num[third:0] == 0)    //1100
            shift_action = {4'b1100, num[first:0]};
        else if(num[first:second+1] != 0 && num[second:third+1] == 0 && num[third:fourth+1] != 0 && num[fourth:0] == 0)    //1010
            shift_action = {4'b1100, num[first:second+1], num[third:fourth+1], 24'd0};
        else if(num[first:second+1] != 0 && num[second:third+1] == 0 && num[third:fourth+1] == 0 && num[fourth:0] != 0)    //1001
            shift_action = {4'b1100, num[first:second+1], num[fourth:0], 24'd0};
        else if(num[first:second+1] == 0 && num[second:third+1] != 0 && num[third:fourth+1] != 0 && num[fourth:0] == 0)    //0110
            shift_action = {4'b1100, num[second:third+1], num[third:fourth+1], 24'd0};
        else if(num[first:second+1] == 0 && num[second:third+1] != 0 && num[third:fourth+1] == 0 && num[fourth:0] != 0)    //0101
            shift_action = {4'b1100, num[second:third+1], num[fourth:0], 24'd0};
        else if(num[first:third+1] == 0 && num[third:fourth+1] != 0 && num[fourth:0] != 0)    //0011
            shift_action = {4'b1100, num[third:0], 24'd0};
            
        else if(num[first:second+1] == 0 && num[second:third+1] != 0 && num[third:fourth+1] != 0 && num[fourth:0] != 0)    //0111
            shift_action = {4'b1110, num[second:0], 12'd0};
        else if(num[first:second+1] != 0 && num[second:third+1] == 0 && num[third:fourth+1] != 0 && num[fourth:0] != 0)    //1011
            shift_action = {4'b1110, num[first:second+1], num[third:0], 12'd0};
        else if(num[first:second+1] != 0 && num[second:third+1] != 0 && num[third:fourth+1] == 0 && num[fourth:0] != 0)    //1101
            shift_action = {4'b1110, num[first:third+1], num[fourth:0], 12'd0};
        else if(num[first:second+1] != 0 && num[second:third+1] != 0 && num[third:fourth+1] != 0 && num[fourth:0] == 0)    //1110
            shift_action = {4'b1110, num[first:0]};
        else      //1111
            shift_action = {4'b1111, num[first:0]};
	end
endfunction 


////////////////////////////////
// New block generation logic
////////////////////////////////
function [total_size-1:0] genRU;
    input [total_size-1:0] data;   
    begin
        if (data[b4_start:b4_end] == 0)
            genRU = {data[b1_start:b3_end], 12'd2, data[b5_start:b16_end]};
        else if (data[b3_start:b3_end] == 0)
            genRU = {data[b1_start:b2_end], 12'd2, data[b4_start:b16_end]};
        else if (data[b8_start:b8_end] == 0)
            genRU = {data[b1_start:b7_end], 12'd2, data[b9_start:b16_end]};
        else if (data[b2_start:b2_end] == 0)
            genRU = {data[b1_start:b1_end], 12'd2, data[b3_start:b16_end]};
        else if (data[b7_start:b7_end] == 0)
            genRU = {data[b1_start:b6_end], 12'd2, data[b8_start:b16_end]};
        else if (data[b12_start:b12_end] == 0)
            genRU = {data[b1_start:b11_end], 12'd2, data[b13_start:b16_end]};
        else if (data[b1_start:b1_end] == 0)
            genRU = {12'd2, data[b2_start:b16_end]};
        else if (data[b6_start:b6_end] == 0)
            genRU = {data[b1_start:b5_end], 12'd2, data[b7_start:b16_end]};
        else if (data[b11_start:b11_end] == 0)
            genRU = {data[b1_start:b10_end], 12'd2, data[b12_start:b16_end]};
        else if (data[b16_start:b16_end] == 0)
            genRU = {data[b1_start:b15_end], 12'd2};
        else if (data[b5_start:b5_end] == 0)
            genRU = {data[b1_start:b4_end], 12'd2, data[b6_start:b16_end]};
        else if (data[b10_start:b10_end] == 0)
            genRU = {data[b1_start:b9_end], 12'd2, data[b11_start:b16_end]};
        else if (data[b15_start:b15_end] == 0)
            genRU = {data[b1_start:b14_end], 12'd2, data[b16_start:b16_end]};
        else if (data[b9_start:b9_end] == 0)
            genRU = {data[b1_start:b8_end], 12'd2, data[b10_start:b16_end]};
        else if (data[b14_start:b14_end] == 0)
            genRU = {data[b1_start:b13_end], 12'd2, data[b15_start:b16_end]};
        else if (data[b13_start:b13_end] == 0)
            genRU = {data[b1_start:b12_end], 12'd2, data[b14_start:b16_end]};
    end
endfunction

function [total_size-1:0] genLD;
    input [total_size-1:0] data;   
    begin
        if (data[b13_start:b13_end] == 0)
            genLD = {data[b1_start:b12_end], 12'd2, data[b14_start:b16_end]};
		else if (data[b14_start:b14_end] == 0)
            genLD = {data[b1_start:b13_end], 12'd2, data[b15_start:b16_end]};
		else if (data[b9_start:b9_end] == 0)
            genLD = {data[b1_start:b8_end], 12'd2, data[b10_start:b16_end]};
		else if (data[b15_start:b15_end] == 0)
            genLD = {data[b1_start:b14_end], 12'd2, data[b16_start:b16_end]};
		else if (data[b10_start:b10_end] == 0)
            genLD = {data[b1_start:b9_end], 12'd2, data[b11_start:b16_end]};
		else if (data[b5_start:b5_end] == 0)
            genLD = {data[b1_start:b4_end], 12'd2, data[b6_start:b16_end]};
		else if (data[b16_start:b16_end] == 0)
            genLD = {data[b1_start:b15_end], 12'd2};
		else if (data[b11_start:b11_end] == 0)
            genLD = {data[b1_start:b10_end], 12'd2, data[b12_start:b16_end]};
		else if (data[b6_start:b6_end] == 0)
            genLD = {data[b1_start:b5_end], 12'd2, data[b7_start:b16_end]};
		else if (data[b1_start:b1_end] == 0)
            genLD = {12'd2, data[b2_start:b16_end]};
		else if (data[b12_start:b12_end] == 0)
            genLD = {data[b1_start:b11_end], 12'd2, data[b13_start:b16_end]};
		else if (data[b7_start:b7_end] == 0)
            genLD = {data[b1_start:b6_end], 12'd2, data[b8_start:b16_end]};
		else if (data[b2_start:b2_end] == 0)
            genLD = {data[b1_start:b1_end], 12'd2, data[b3_start:b16_end]};
		else if (data[b8_start:b8_end] == 0)
            genLD = {data[b1_start:b7_end], 12'd2, data[b9_start:b16_end]};
		else if (data[b3_start:b3_end] == 0)
            genLD = {data[b1_start:b2_end], 12'd2, data[b4_start:b16_end]};
		else if (data[b4_start:b4_end] == 0)
            genLD = {data[b1_start:b3_end], 12'd2, data[b5_start:b16_end]};
    end
endfunction

always @(*)
begin
	if(rst)
	begin
		win = 0;
		lose = 0;
		max = 0;
	end
	else
	begin
		win = data[b1_start] | data[b2_start] | data[b3_start] | data[b4_start] | data[b5_start] | data[b6_start] | data[b7_start] | data[b8_start] | data[b9_start] | data[b10_start] | data[b11_start] | data[b12_start] | data[b13_start] | data[b14_start] | data[b15_start] | data[b16_start];
		// lose = (all blocks are not 0) & (cannot merge);
		lose = ((|data[b1_start:b1_end])&(|data[b2_start:b2_end])&(|data[b3_start:b3_end])&(|data[b4_start:b4_end])&(|data[b5_start:b5_end])&(|data[b6_start:b6_end])&(|data[b7_start:b7_end])&(|data[b8_start:b8_end])&(|data[b9_start:b9_end])&(|data[b10_start:b10_end])&(|data[b11_start:b11_end])&(|data[b12_start:b12_end])&(|data[b13_start:b13_end])&(|data[b14_start:b14_end])&(|data[b15_start:b15_end])&(|data[b16_start:b16_end])) 
				& (~merge_success);
		// max
		if(data[b1_start] | data[b2_start] | data[b3_start] | data[b4_start] | data[b5_start] | data[b6_start] | data[b7_start] | data[b8_start] | data[b9_start] | data[b10_start] | data[b11_start] | data[b12_start] | data[b13_start] | data[b14_start] | data[b15_start] | data[b16_start])
			max = 12'd2048;
		else if(data[b1_start-1] | data[b2_start-1] | data[b3_start-1] | data[b4_start-1] | data[b5_start-1] | data[b6_start-1] | data[b7_start-1] | data[b8_start-1] | data[b9_start-1] | data[b10_start-1] | data[b11_start-1] | data[b12_start-1] | data[b13_start-1] | data[b14_start-1] | data[b15_start-1] | data[b16_start-1])
			max = 12'd1024;
		else if(data[b1_start-2] | data[b2_start-2] | data[b3_start-2] | data[b4_start-2] | data[b5_start-2] | data[b6_start-2] | data[b7_start-2] | data[b8_start-2] | data[b9_start-2] | data[b10_start-2] | data[b11_start-2] | data[b12_start-2] | data[b13_start-2] | data[b14_start-2] | data[b15_start-2] | data[b16_start-2])
			max = 12'd512;
		else if(data[b1_start-3] | data[b2_start-3] | data[b3_start-3] | data[b4_start-3] | data[b5_start-3] | data[b6_start-3] | data[b7_start-3] | data[b8_start-3] | data[b9_start-3] | data[b10_start-3] | data[b11_start-3] | data[b12_start-3] | data[b13_start-3] | data[b14_start-3] | data[b15_start-3] | data[b16_start-3])
			max = 12'd256;
		else if(data[b1_start-4] | data[b2_start-4] | data[b3_start-4] | data[b4_start-4] | data[b5_start-4] | data[b6_start-4] | data[b7_start-4] | data[b8_start-4] | data[b9_start-4] | data[b10_start-4] | data[b11_start-4] | data[b12_start-4] | data[b13_start-4] | data[b14_start-4] | data[b15_start-4] | data[b16_start-4])
			max = 12'd128;
		else if(data[b1_start-5] | data[b2_start-5] | data[b3_start-5] | data[b4_start-5] | data[b5_start-5] | data[b6_start-5] | data[b7_start-5] | data[b8_start-5] | data[b9_start-5] | data[b10_start-5] | data[b11_start-5] | data[b12_start-5] | data[b13_start-5] | data[b14_start-5] | data[b15_start-5] | data[b16_start-5])
			max = 12'd64;
		else if(data[b1_start-6] | data[b2_start-6] | data[b3_start-6] | data[b4_start-6] | data[b5_start-6] | data[b6_start-6] | data[b7_start-6] | data[b8_start-6] | data[b9_start-6] | data[b10_start-6] | data[b11_start-6] | data[b12_start-6] | data[b13_start-6] | data[b14_start-6] | data[b15_start-6] | data[b16_start-6])
			max = 12'd32;
		else if(data[b1_start-7] | data[b2_start-7] | data[b3_start-7] | data[b4_start-7] | data[b5_start-7] | data[b6_start-7] | data[b7_start-7] | data[b8_start-7] | data[b9_start-7] | data[b10_start-7] | data[b11_start-7] | data[b12_start-7] | data[b13_start-7] | data[b14_start-7] | data[b15_start-7] | data[b16_start-7])
			max = 12'd16;
		else if(data[b1_start-8] | data[b2_start-8] | data[b3_start-8] | data[b4_start-8] | data[b5_start-8] | data[b6_start-8] | data[b7_start-8] | data[b8_start-8] | data[b9_start-8] | data[b10_start-8] | data[b11_start-8] | data[b12_start-8] | data[b13_start-8] | data[b14_start-8] | data[b15_start-8] | data[b16_start-8])
			max = 12'd8;
		else if(data[b1_start-9] | data[b2_start-9] | data[b3_start-9] | data[b4_start-9] | data[b5_start-9] | data[b6_start-9] | data[b7_start-9] | data[b8_start-9] | data[b9_start-9] | data[b10_start-9] | data[b11_start-9] | data[b12_start-9] | data[b13_start-9] | data[b14_start-9] | data[b15_start-9] | data[b16_start-9])
			max = 12'd4;
		else if(data[b1_start-10] | data[b2_start-10] | data[b3_start-10] | data[b4_start-10] | data[b5_start-10] | data[b6_start-10] | data[b7_start-10] | data[b8_start-10] | data[b9_start-10] | data[b10_start-10] | data[b11_start-10] | data[b12_start-10] | data[b13_start-10] | data[b14_start-10] | data[b15_start-10] | data[b16_start-10])
			max = 12'd2;
		else 
			max = 12'd0;
	end
end


always @(posedge clk)
begin
	// Reset
	if (rst)
	begin
		state <= S_gen;
	end
	else if ((state[1:0] == S_init) & (btnD | btnL | btnR | btnU) & new_clk_500hz & ~lose & ~win)
    begin
		state <= S_merge;
        ctrl <= {btnU, btnD, btnL, btnR};
    end
	else if (!(state[1:0] == S_init))
		state <= state + 1;
end

always @(posedge clk)      // add conditions on win/lose
begin
	if (rst)
	begin
		data [total_size-1:0] <= 0;
        bmap [15:0] <= 0;
        merge_success <= 1;
	end
	else
	begin
		case(state)
			S_init:
			begin
			end
			S_merge:
			begin
				if(btnU)
				begin
					{data[b1_start:b1_end],data[b5_start:b5_end],data[b9_start:b9_end],data[b13_start:b13_end]} 
						<= merge_action({data[b1_start:b1_end],data[b5_start:b5_end],data[b9_start:b9_end],data[b13_start:b13_end]});               
					{data[b2_start:b2_end],data[b6_start:b6_end],data[b10_start:b10_end],data[b14_start:b14_end]} 
						<= merge_action({data[b2_start:b2_end],data[b6_start:b6_end],data[b10_start:b10_end],data[b14_start:b14_end]});
					{data[b3_start:b3_end],data[b7_start:b7_end],data[b11_start:b11_end],data[b15_start:b15_end]} 
						<= merge_action({data[b3_start:b3_end],data[b7_start:b7_end],data[b11_start:b11_end],data[b15_start:b15_end]});
					{data[b4_start:b4_end],data[b8_start:b8_end],data[b12_start:b12_end],data[b16_start:b16_end]} 
						<= merge_action({data[b4_start:b4_end],data[b8_start:b8_end],data[b12_start:b12_end],data[b16_start:b16_end]});
				end
				else if(btnD)
				begin
					{data[b13_start:b13_end],data[b9_start:b9_end],data[b5_start:b5_end],data[b1_start:b1_end]} 
						<= merge_action({data[b13_start:b13_end],data[b9_start:b9_end],data[b5_start:b5_end],data[b1_start:b1_end]});
					{data[b14_start:b14_end],data[b10_start:b10_end],data[b6_start:b6_end],data[b2_start:b2_end]} 
						<= merge_action({data[b14_start:b14_end],data[b10_start:b10_end],data[b6_start:b6_end],data[b2_start:b2_end]});
					{data[b15_start:b15_end],data[b11_start:b11_end],data[b7_start:b7_end],data[b3_start:b3_end]}
						<= merge_action({data[b15_start:b15_end],data[b11_start:b11_end],data[b7_start:b7_end],data[b3_start:b3_end]});
					{data[b16_start:b16_end],data[b12_start:b12_end],data[b8_start:b8_end],data[b4_start:b4_end]}
						<= merge_action({data[b16_start:b16_end],data[b12_start:b12_end],data[b8_start:b8_end],data[b4_start:b4_end]});
				end
				else if(btnL)
				begin
					{data[b1_start:b1_end],data[b2_start:b2_end],data[b3_start:b3_end],data[b4_start:b4_end]}
						<= merge_action({data[b1_start:b1_end],data[b2_start:b2_end],data[b3_start:b3_end],data[b4_start:b4_end]});
					{data[b5_start:b5_end],data[b6_start:b6_end],data[b7_start:b7_end],data[b8_start:b8_end]}
						<= merge_action({data[b5_start:b5_end],data[b6_start:b6_end],data[b7_start:b7_end],data[b8_start:b8_end]});
					{data[b9_start:b9_end],data[b10_start:b10_end],data[b11_start:b11_end],data[b12_start:b12_end]}
						<= merge_action({data[b9_start:b9_end],data[b10_start:b10_end],data[b11_start:b11_end],data[b12_start:b12_end]});
					{data[b13_start:b13_end],data[b14_start:b14_end],data[b15_start:b15_end],data[b16_start:b16_end]}
						<= merge_action({data[b13_start:b13_end],data[b14_start:b14_end],data[b15_start:b15_end],data[b16_start:b16_end]});
				end
				else if(btnR)
				begin
					{data[b4_start:b4_end],data[b3_start:b3_end],data[b2_start:b2_end],data[b1_start:b1_end]}
						<= merge_action({data[b4_start:b4_end],data[b3_start:b3_end],data[b2_start:b2_end],data[b1_start:b1_end]});
					{data[b8_start:b8_end],data[b7_start:b7_end],data[b6_start:b6_end],data[b5_start:b5_end]}
						<= merge_action({data[b8_start:b8_end],data[b7_start:b7_end],data[b6_start:b6_end],data[b5_start:b5_end]});
					{data[b12_start:b12_end],data[b11_start:b11_end],data[b10_start:b10_end],data[b9_start:b9_end]}
						<= merge_action({data[b12_start:b12_end],data[b11_start:b11_end],data[b10_start:b10_end],data[b9_start:b9_end]});
					{data[b16_start:b16_end],data[b15_start:b15_end],data[b14_start:b14_end],data[b13_start:b13_end]}
						<= merge_action({data[b16_start:b16_end],data[b15_start:b15_end],data[b14_start:b14_end],data[b13_start:b13_end]});
				end
			end

			S_shift:
			begin
                if(btnU)
				begin
					{bmap[b1],bmap[b5],bmap[b9],bmap[b13],data[b1_start:b1_end],data[b5_start:b5_end],data[b9_start:b9_end],data[b13_start:b13_end]} 
						<= shift_action({data[b1_start:b1_end],data[b5_start:b5_end],data[b9_start:b9_end],data[b13_start:b13_end]});
					{bmap[b2],bmap[b6],bmap[b10],bmap[b14],data[b2_start:b2_end],data[b6_start:b6_end],data[b10_start:b10_end],data[b14_start:b14_end]} 
						<= shift_action({data[b2_start:b2_end],data[b6_start:b6_end],data[b10_start:b10_end],data[b14_start:b14_end]});
					{bmap[b3],bmap[b7],bmap[b11],bmap[b15],data[b3_start:b3_end],data[b7_start:b7_end],data[b11_start:b11_end],data[b15_start:b15_end]} 
						<= shift_action({data[b3_start:b3_end],data[b7_start:b7_end],data[b11_start:b11_end],data[b15_start:b15_end]});
					{bmap[b4],bmap[b8],bmap[b12],bmap[b16],data[b4_start:b4_end],data[b8_start:b8_end],data[b12_start:b12_end],data[b16_start:b16_end]} 
						<= shift_action({data[b4_start:b4_end],data[b8_start:b8_end],data[b12_start:b12_end],data[b16_start:b16_end]});
				end
				else if(btnD)
				begin
					{bmap[b13],bmap[b9],bmap[b5],bmap[b1],data[b13_start:b13_end],data[b9_start:b9_end],data[b5_start:b5_end],data[b1_start:b1_end]} 
						<= shift_action({data[b13_start:b13_end],data[b9_start:b9_end],data[b5_start:b5_end],data[b1_start:b1_end]});
					{bmap[b14],bmap[b10],bmap[b6],bmap[b2],data[b14_start:b14_end],data[b10_start:b10_end],data[b6_start:b6_end],data[b2_start:b2_end]} 
						<= shift_action({data[b14_start:b14_end],data[b10_start:b10_end],data[b6_start:b6_end],data[b2_start:b2_end]});
					{bmap[b15],bmap[b11],bmap[b7],bmap[b3],data[b15_start:b15_end],data[b11_start:b11_end],data[b7_start:b7_end],data[b3_start:b3_end]}
						<= shift_action({data[b15_start:b15_end],data[b11_start:b11_end],data[b7_start:b7_end],data[b3_start:b3_end]});
					{bmap[b16],bmap[b12],bmap[b8],bmap[b4],data[b16_start:b16_end],data[b12_start:b12_end],data[b8_start:b8_end],data[b4_start:b4_end]}
						<= shift_action({data[b16_start:b16_end],data[b12_start:b12_end],data[b8_start:b8_end],data[b4_start:b4_end]});
				end
				else if(btnL)
				begin
					{bmap[b1],bmap[b2],bmap[b3],bmap[b4],data[b1_start:b1_end],data[b2_start:b2_end],data[b3_start:b3_end],data[b4_start:b4_end]}
						<= shift_action({data[b1_start:b1_end],data[b2_start:b2_end],data[b3_start:b3_end],data[b4_start:b4_end]});
					{bmap[b5],bmap[b6],bmap[b7],bmap[b8],data[b5_start:b5_end],data[b6_start:b6_end],data[b7_start:b7_end],data[b8_start:b8_end]}
						<= shift_action({data[b5_start:b5_end],data[b6_start:b6_end],data[b7_start:b7_end],data[b8_start:b8_end]});
					{bmap[b9],bmap[b10],bmap[b11],bmap[b12],data[b9_start:b9_end],data[b10_start:b10_end],data[b11_start:b11_end],data[b12_start:b12_end]}
						<= shift_action({data[b9_start:b9_end],data[b10_start:b10_end],data[b11_start:b11_end],data[b12_start:b12_end]});
					{bmap[b13],bmap[b14],bmap[b15],bmap[b16],data[b13_start:b13_end],data[b14_start:b14_end],data[b15_start:b15_end],data[b16_start:b16_end]}
						<= shift_action({data[b13_start:b13_end],data[b14_start:b14_end],data[b15_start:b15_end],data[b16_start:b16_end]});
				end
				else if(btnR)
				begin
					{bmap[b4],bmap[b3],bmap[b2],bmap[b1],data[b4_start:b4_end],data[b3_start:b3_end],data[b2_start:b2_end],data[b1_start:b1_end]}
						<= shift_action({data[b4_start:b4_end],data[b3_start:b3_end],data[b2_start:b2_end],data[b1_start:b1_end]});
					{bmap[b8],bmap[b7],bmap[b6],bmap[b5],data[b8_start:b8_end],data[b7_start:b7_end],data[b6_start:b6_end],data[b5_start:b5_end]}
						<= shift_action({data[b8_start:b8_end],data[b7_start:b7_end],data[b6_start:b6_end],data[b5_start:b5_end]});
					{bmap[b12],bmap[b11],bmap[b10],bmap[b9],data[b12_start:b12_end],data[b11_start:b11_end],data[b10_start:b10_end],data[b9_start:b9_end]}
						<= shift_action({data[b12_start:b12_end],data[b11_start:b11_end],data[b10_start:b10_end],data[b9_start:b9_end]});
					{bmap[b16],bmap[b15],bmap[b14],bmap[b13],data[b16_start:b16_end],data[b15_start:b15_end],data[b14_start:b14_end],data[b13_start:b13_end]}
						<= shift_action({data[b16_start:b16_end],data[b15_start:b15_end],data[b14_start:b14_end],data[b13_start:b13_end]});
				end
			end
            
			S_gen:
			begin
				merge_success <= ~(&bmap[15:0]);
				if(!lose && !win)
				begin
				// genRU, genLD
				if (diff[0]) // Far side
				begin
					if (ctrl[3] | ctrl[0])	// U or R, use genLD
						data[b1_start:0] <= genLD(data[b1_start:0]);
					else 	// Start, L or D, use genRU
						data[b1_start:0] <= genRU(data[b1_start:0]);
				end
				else // Near side
					begin
						if (ctrl[3] | ctrl[0])	// U or R, use genRU
							data[b1_start:0] <= genRU(data[b1_start:0]);
						else // Start, L or D, use genLD
							data[b1_start:0] <= genLD(data[b1_start:0]);
					end
					end
			//data[b1_start:0] <= {12'd512, 12'd256, 12'd128, 12'd64, 12'd256, 12'd128, 12'd64, 12'd32, 12'd128, 12'd64, 12'd32, 12'd16, 12'd64, 12'd32, 12'd16, 12'd8};
			end
		endcase
	end
end

endmodule 