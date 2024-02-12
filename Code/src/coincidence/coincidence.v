`include "coincidence_buffer.v"

module coincidence (
	clk,
	rst,
	
	idata_A,
	idata_A_en,
	idata_B,
	idata_B_en,
	
    timing_window,

	odata_A,
	odata_B,
	odata_en
);

parameter COINCIDENCE_DATA_A_WIDTH = 128;
parameter COINCIDENCE_DATA_B_WIDTH = 128;
parameter COINCIDENCE_DATA_A_TIME_START = 72;
parameter COINCIDENCE_DATA_B_TIME_START = 72;
parameter COINCIDENCE_TIME_WIDTH = 24;
parameter COINCIDENCE_BIAS_A_B = 1;
parameter COINCIDENCE_BIAS_B_A = 1;

input clk;
input rst;

input [COINCIDENCE_DATA_A_WIDTH-1:0] idata_A;
input idata_A_en;
input [COINCIDENCE_DATA_B_WIDTH-1:0] idata_B;
input idata_B_en;

input [7:0] timing_window; // unit: 5ns. e.g. set timing_window = 10 --> coincidence window is 50ns

output [COINCIDENCE_DATA_A_WIDTH-1:0] odata_A;
output [COINCIDENCE_DATA_B_WIDTH-1:0] odata_B;
output reg odata_en;

reg [COINCIDENCE_DATA_A_WIDTH-1:0] idata_A_buf;
reg idata_A_en_buf;
reg [COINCIDENCE_DATA_B_WIDTH-1:0] idata_B_buf;
reg idata_B_en_buf;
always@(posedge clk) begin
	idata_A_buf <= idata_A;
	idata_B_buf <= idata_B;
	idata_A_en_buf <= idata_A_en;
	idata_B_en_buf <= idata_B_en;
end

wire empty_A;
wire empty_B;

reg odata_req_A;

reg req_A;
reg req_A_buf;
reg req_B;
reg req_B_buf;

wire [COINCIDENCE_DATA_A_WIDTH-1:0] odata_A_fifo;
wire [COINCIDENCE_DATA_B_WIDTH-1:0] odata_B_fifo;

coincidence_buffer #(.COINCIDENCE_BUFFER_WIDTH(COINCIDENCE_DATA_A_WIDTH)) detectorA_buffer_inst(
	.clk(clk),
	.rst(rst),
	
	.idata(idata_A_buf),
	.idata_en(idata_A_en_buf),
	
	.buffer_empty(empty_A),
	.odata_req(req_A),
	.odata(odata_A_fifo)
);
coincidence_buffer #(.COINCIDENCE_BUFFER_WIDTH(COINCIDENCE_DATA_B_WIDTH)) detectorB_buffer_inst(
	.clk(clk),
	.rst(rst),
	
	.idata(idata_B_buf),
	.idata_en(idata_B_en_buf),
	
	.buffer_empty(empty_B),
	.odata_req(req_B),
	.odata(odata_B_fifo)
);

wire [COINCIDENCE_TIME_WIDTH-1:0] event_time_A, event_time_B;
assign event_time_A = odata_A_fifo[COINCIDENCE_DATA_A_TIME_START+COINCIDENCE_TIME_WIDTH-1:COINCIDENCE_DATA_A_TIME_START];
assign event_time_B = odata_B_fifo[COINCIDENCE_DATA_B_TIME_START+COINCIDENCE_TIME_WIDTH-1:COINCIDENCE_DATA_B_TIME_START];

//=================================State Machine==================/
reg event_ready;
reg event_A_ready, event_B_ready;
reg coincidence_success, coincidence_fail;

wire time_diff_en;
reg sign_A, sign_B;
reg cmp_en;

reg [3:0] current_state,next_state;

localparam STATE0_WAIT = 0;
localparam STATE1_POP_AB = 1;
localparam STATE2_POP_AB_DELAY = 2;
localparam STATE3_CMP = 3;
localparam STATE4_OUTPUT = 4;

// State jump
always@(posedge clk or posedge rst) begin
	if(rst) begin
		current_state <= STATE0_WAIT;
	end
	else begin
		current_state <= next_state;
	end
end

always@(*) begin
	case(current_state)
		STATE0_WAIT: begin
			if(~event_B_ready|~event_A_ready) begin
				next_state = STATE1_POP_AB;
			end
			else begin
				next_state = STATE3_CMP;
			end
		end
		STATE1_POP_AB: begin
			next_state = STATE2_POP_AB_DELAY;
		end
		STATE2_POP_AB_DELAY:begin
			next_state = STATE0_WAIT;
		end
        STATE3_CMP: begin
			if(coincidence_success) begin
				next_state = STATE4_OUTPUT;
			end
			else if(coincidence_fail) begin
				next_state = STATE0_WAIT;
			end
			else
				next_state = STATE3_CMP;
        end
        STATE4_OUTPUT: begin
			next_state = STATE0_WAIT;
        end
		default: begin
			next_state = STATE0_WAIT;
		end
	endcase
end

// Comb out

always@(posedge clk or posedge rst) begin
    if(rst) begin
		event_A_ready <= 0;
		event_B_ready <= 0;
		cmp_en <= 0;
	end
    else
        case(current_state)
            STATE0_WAIT: begin 
				cmp_en <= 0;
				coincidence_success <= 0;
				coincidence_fail <= 0;
				odata_en <= 0;
				req_A <= 0;
				req_B <= 0;
            end
            STATE1_POP_AB: begin
				if(~empty_A && ~event_A_ready) begin
					req_A <= 1;
					event_A_ready <= 1;
				end
				else begin
					req_A <= 0;
				end
				if(~empty_B && ~event_B_ready) begin
					req_B <= 1;
					event_B_ready <= 1;
				end
				else begin
					req_B <= 0;
				end
            end
			STATE2_POP_AB_DELAY: begin
				req_A <= 0;
				req_B <= 0;
			end
            STATE3_CMP: begin
				cmp_en <= 1;
				if(time_diff_en) begin
					case ({sign_A,sign_B})
						2'b00:begin
							// Impossible.
						end
						2'b10:begin
							coincidence_fail <= 1;
							event_B_ready <= 0;
						end
						2'b01:begin
							coincidence_fail <= 1;
							event_A_ready <= 0;
						end
						2'b11: begin
							coincidence_success <= 1;
							event_A_ready <= 0;
							event_B_ready <= 0;
						end
						
					endcase
				end

            end
            STATE4_OUTPUT:begin
				cmp_en <= 0;
				coincidence_success <= 0;
				odata_en <= 1;
            end
            default: begin
				odata_en <= 0;
				cmp_en <= 0;
				req_A <= 0;
				req_B <= 0;
            end
        endcase
end



// compare
reg [COINCIDENCE_TIME_WIDTH-1:0] event_time_A_cmp, event_time_B_cmp;
reg [COINCIDENCE_TIME_WIDTH-1:0] event_time_A_cmp_winright,event_time_B_cmp_winright;
reg [COINCIDENCE_TIME_WIDTH-1:0] sub_result_A_Awin_right,sub_result_A_Bwin_right;

reg [COINCIDENCE_TIME_WIDTH-1:0] event_time_A_reg, event_time_B_reg;
reg [COINCIDENCE_TIME_WIDTH-1:0] event_time_A_reg_dup, event_time_B_reg_dup;
always@(posedge clk or posedge rst) begin
    if(rst) begin
		event_time_A_cmp<=0;
		event_time_B_cmp<=0;
		event_time_A_reg<=0;
		event_time_B_reg<=0;
	end
	else begin
		req_A_buf <= req_A;
		req_B_buf <= req_B;
		if(req_A_buf) begin
			//odata_A <= odata_A_fifo;
			event_time_A_reg <= event_time_A;
			event_time_A_reg_dup <= event_time_A;
		end
		if(req_B_buf) begin
			//odata_B <= odata_B_fifo;
			event_time_B_reg <= event_time_B;
			event_time_B_reg_dup <= event_time_B;
		end
		event_time_A_cmp <= event_time_A_reg + COINCIDENCE_BIAS_B_A;
		event_time_B_cmp <= event_time_B_reg + COINCIDENCE_BIAS_A_B;

		event_time_A_cmp_winright <= event_time_A_reg + timing_window + COINCIDENCE_BIAS_B_A;
		event_time_B_cmp_winright <= event_time_B_reg + timing_window + COINCIDENCE_BIAS_A_B;

		sub_result_A_Bwin_right <= event_time_A_cmp - event_time_B_cmp_winright;
		sub_result_A_Awin_right <= event_time_B_cmp - event_time_A_cmp_winright;

		sign_A <= sub_result_A_Awin_right[COINCIDENCE_TIME_WIDTH-1] == 1;
		sign_B <= sub_result_A_Bwin_right[COINCIDENCE_TIME_WIDTH-1] == 1;
	end
end

assign odata_A = odata_A_fifo;
assign odata_B = odata_B_fifo;


`define CMP_SIG_DLY 2
reg [`CMP_SIG_DLY:0] compare_en_delay;
always@(posedge clk or posedge rst) begin
    if(rst) begin

	end
	else begin
		compare_en_delay[0] <= cmp_en;
        compare_en_delay[`CMP_SIG_DLY:1] <= compare_en_delay[`CMP_SIG_DLY-1:0];
	end
end
assign time_diff_en = ~compare_en_delay[`CMP_SIG_DLY] && compare_en_delay[`CMP_SIG_DLY-1];

endmodule