module game2048 (
    btnS, btnL, btnR, btnU, btnD, clk, RsRx, sw,     // Input
    AN, SEG, RsTx                                   // Output
);

`include "game_definitions_g04.v"

input 	btnS, btnL, btnR, btnU, btnD, clk, RsRx;
input   [1:0]   sw;
output  [3:0]   AN;
output  [6:0]   SEG;
output  RsTx;

wire        rst;
wire        arst_i;
reg [1:0]   arst_ff;

reg         inst_vld;

wire        clk_fst;
reg [16:0]  clk_dv;
wire [17:0]  clk_dv_inc;
reg         clk_en;
reg         clk_en_d;
reg         clk_en_dd;
reg         clk_en_ddd;
reg         clk_en_dddd;

reg [2:0]   step_d_L;
reg [2:0]   step_d_R;
reg [2:0]   step_d_U;
reg [2:0]   step_d_D;

wire    [total_size-1:0]     data;
wire    [block_size-1:0]      max;

/*AUTOWIRE*/
// Beginning of automatic wires (for undeclared instantiated-module outputs)
wire                 game_tx_valid; 
wire [7:0]           uart_rx_data;           // From uart_top_ of uart_top.v
wire                 uart_rx_valid;          // From uart_top_ of uart_top.v
wire                 uart_tx_busy;           // From uart_top_ of uart_top.v
// End of automatics

// ===========================================================================
// Asynchronous Reset
// ===========================================================================

assign arst_i = btnS;
assign rst = arst_ff[0];

always @ (posedge clk or posedge arst_i)
begin
    if (arst_i)
    arst_ff <= 2'b11;
    else
    arst_ff <= {1'b0, arst_ff[1]};
end

// ===========================================================================
// Clock divider
// ===========================================================================

clk_div clk_div_ (
    // Outputs
    .clk_fst        (clk_fst),
    // Inputs
    .clk             (clk), 
    .rst             (rst)
);

// ===========================================================================
// timing signal for clock enable
// ===========================================================================

assign clk_dv_inc = clk_dv + 1;

always @ (posedge clk)
 if (rst)
   begin
      clk_dv   <= 0;
      clk_en   <= 1'b0;
      clk_en_d <= 1'b0;
      clk_en_dd <= 1'b0;
      clk_en_ddd <= 1'b0;
      clk_en_dddd <= 1'b0;
   end
 else
   begin
      clk_dv   <= clk_dv_inc[16:0];
      clk_en   <= clk_dv_inc[17];
      clk_en_d <= clk_en;
	  clk_en_dd <= clk_en_d;
	  clk_en_ddd <= clk_en_dd;
	  clk_en_dddd <= clk_en_ddd;
   end

// ===========================================================================
// Debouncing
// ===========================================================================
always @ (posedge clk)
    if (rst)
    begin
        step_d_L[2:0]  <= 0;
        step_d_R[2:0]  <= 0;
        step_d_U[2:0]  <= 0;
        step_d_D[2:0]  <= 0;
    end
    else if (clk_en) // Down sampling
    begin
        step_d_L[2:0]  <= {btnL, step_d_L[2:1]};
        step_d_R[2:0]  <= {btnR, step_d_R[2:1]};
        step_d_U[2:0]  <= {btnU, step_d_U[2:1]};
        step_d_D[2:0]  <= {btnD, step_d_D[2:1]};
    end

// Detecting posedge of buttons
wire is_btnL_posedge;
wire is_btnR_posedge;
wire is_btnU_posedge;
wire is_btnD_posedge;
assign is_btnL_posedge = ~ step_d_L[0] & step_d_L[1];
assign is_btnR_posedge = ~ step_d_R[0] & step_d_R[1];
assign is_btnU_posedge = ~ step_d_U[0] & step_d_U[1];
assign is_btnD_posedge = ~ step_d_D[0] & step_d_D[1];

always @ (posedge clk)
 if (rst)
 begin
   inst_vld <= 1'b0;
 end
 else if (clk_en_dddd)
 begin
   inst_vld <= is_btnL_posedge | is_btnR_posedge | is_btnD_posedge | is_btnU_posedge;
 end 
 else
 begin
    inst_vld <= 0;
end

game_logic game_logic_ (
    // Inputs
    .btnL(is_btnL_posedge), .btnR(is_btnR_posedge), .btnD(is_btnD_posedge), 
    .btnU(is_btnU_posedge), .rst(rst), .clk(clk), .diff(sw), 
    .i_tx_busy(uart_tx_busy),
    .i_valid(inst_vld),
    // Output
    .data(data), .max(max), .o_valid(game_tx_valid)
);

display_controller display_controller_(
    // Outputs
    .AN(AN), .SEG(SEG),
    // Inputs
    .clk_500hz(clk_fst), .rst(rst), .value(max)
);

// ===========================================================================
// UART controller
// ===========================================================================

uart_top uart_top_ (// Outputs
                   .o_tx            (RsTx),
                   .o_tx_busy       (uart_tx_busy),
                   .o_rx_data       (uart_rx_data[7:0]),
                   .o_rx_valid      (uart_rx_valid),
                   // Inputs
                   .i_rx            (RsRx),
                   .i_tx_data       (data[total_size-1:0]),
                   .i_tx_stb        (game_tx_valid),

                   /*AUTOINST*/
                   // Inputs
                   .clk             (clk),
                   .rst             (rst));

endmodule 