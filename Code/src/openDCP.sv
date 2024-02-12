`include "coincidence/dcp_pairs.sv"
`include "coincidence/delay_pairs.sv"
`include "coincidence/coincidence.v"
`include "coincidence/rotating_bus.sv"
`include "random_event_gen/random_event_gen.sv"

module openDCP(
    clk_200M,
    rst_n,


    test_mode,
    timing_window,
    
    event_data,
    event_data_en,

    coincidence_data,
    coincidence_data_en
);

//=======================================================
//  PARAMETER declarations
//=======================================================
parameter LVDS_CHAN_NUM = 8'd32;
parameter CHANNEL_TIMING_WIDTH = 8'd32 + 8'd16 + 8'd8;
parameter TIMING_START_POS = 16*4, TIMING_COARSE_POS = 16*4+8, TIMING_COARSE_WIDTH = 24;
parameter P_WIDTH = 8'd16, E_WIDTH = 8'd16, BOARDID_WIDTH = 8'd8;
parameter DETECTOR_DATA_WIDTH = P_WIDTH*2 + E_WIDTH*2 + CHANNEL_TIMING_WIDTH + BOARDID_WIDTH;
parameter PAIR_WIDTH = 8'd16; parameter PAIR_DATA_WIDTH = DETECTOR_DATA_WIDTH*2 + PAIR_WIDTH;

//=======================================================
//  Port declarations
//=======================================================
input                               clk_200M;
input                               rst_n;

input                     [1:0]     test_mode;
input                     [7:0]     timing_window; // unit: 5ns. e.g. set timing_window = 10 --> coincidence window is +-50ns

input [DETECTOR_DATA_WIDTH-1:0]     event_data              [LVDS_CHAN_NUM-1:0];
input       [LVDS_CHAN_NUM-1:0]     event_data_en;

output    [PAIR_DATA_WIDTH-1:0]     coincidence_data;
output                              coincidence_data_en;

//=======================================================
//  Internal event generation for testing
//=======================================================
////////////Gen Interval Ctrl////////////
    reg [31:0] gen_cnt; reg gen_en;
    always @(posedge clk_200M or negedge rst_n) begin
        if(~rst_n) begin
            gen_cnt <= 31'd0;
            gen_en <= 1'b0;
        end
        else begin  
            // biger speed_ctrl --> larger interval
            if(test_mode) begin 
                gen_cnt <= (gen_cnt == ({24'h0, 8'd128} << 18)) ? 32'd0 : gen_cnt + 1'b1;
                gen_en <= gen_cnt == 32'd1 ? 1'b1: 1'b0;
            end
            else begin
                gen_cnt <= 31'd0;
                gen_en <= 1'b0;
            end
        end
    end

////////////Random Gen////////////
wire [DETECTOR_DATA_WIDTH-1:0] event_data_i [LVDS_CHAN_NUM-1:0];
wire [LVDS_CHAN_NUM-1:0] event_data_en_i;
random_event_gen reg_inst(
    .clk(clk_200M),
    .rst_n(rst_n),
    
    .mode(test_mode),
    .en(gen_en),
    .event_data(event_data_i),
    .event_data_en(event_data_en_i)
);
defparam
    reg_inst.DETECTOR_DATA_WIDTH = DETECTOR_DATA_WIDTH,
    reg_inst.LVDS_CHAN_NUM       = LVDS_CHAN_NUM;

//=======================================================
//  Coincidence Processors
//=======================================================
////////////Data Switch////////////
reg [DETECTOR_DATA_WIDTH-1:0] event_data_for_coin [LVDS_CHAN_NUM-1:0];
reg [LVDS_CHAN_NUM-1:0] event_data_en_for_coin; 
integer jj;
always @(posedge clk_200M or negedge rst_n) begin
    if(~rst_n) begin
        event_data_en_for_coin <= {LVDS_CHAN_NUM{1'b0}};
        for(jj = 0; jj < LVDS_CHAN_NUM; jj++)
            event_data_for_coin[jj] <= {DETECTOR_DATA_WIDTH{1'b0}};
    end
    else begin
        if(test_mode) begin
            event_data_en_for_coin <= event_data_en_i;
            for(jj = 0; jj < LVDS_CHAN_NUM; jj++)
                event_data_for_coin[jj] <= event_data_i[jj];
        end
        else begin
            event_data_en_for_coin <= event_data_en;
            for(jj = 0; jj < LVDS_CHAN_NUM; jj++)
                event_data_for_coin[jj] <= event_data[jj];
        end
    end
end

////////////DCPs////////////
wire [DETECTOR_DATA_WIDTH-1:0] coin_odata_A [PAIR_NUM-1:0]; 
wire [DETECTOR_DATA_WIDTH-1:0] coin_odata_B [PAIR_NUM-1:0];
wire [PAIR_DATA_WIDTH-1:0] coin_pair_data [PAIR_NUM-1:0]; wire [PAIR_NUM-1:0] coin_odata_en; 
genvar ii;
generate
    for (ii = 0; ii < PAIR_NUM; ii++) begin:gen_coin
        coincidence coin_inst(
            .clk(clk_200M),
            .rst(~rst_n),

            .idata_A(event_data_for_coin[COINCIDENCE_PAIR_MAT[ii][0]]),
            .idata_A_en(event_data_en_for_coin[COINCIDENCE_PAIR_MAT[ii][0]]),
            .idata_B(event_data_for_coin[COINCIDENCE_PAIR_MAT[ii][1]]),
            .idata_B_en(event_data_en_for_coin[COINCIDENCE_PAIR_MAT[ii][1]]),

            .timing_window(timing_window),

            .odata_A(coin_odata_A[ii]),
            .odata_B(coin_odata_B[ii]),
            .odata_en(coin_odata_en[ii])
        );
        defparam 
        coin_inst.COINCIDENCE_DATA_A_WIDTH          = DETECTOR_DATA_WIDTH,
        coin_inst.COINCIDENCE_DATA_B_WIDTH          = DETECTOR_DATA_WIDTH,
        coin_inst.COINCIDENCE_DATA_A_TIME_START     = TIMING_COARSE_POS,
        coin_inst.COINCIDENCE_DATA_B_TIME_START     = TIMING_COARSE_POS,
        coin_inst.COINCIDENCE_TIME_WIDTH            = TIMING_COARSE_WIDTH,
        coin_inst.COINCIDENCE_BIAS_A_B              = CHAN_DELAY_MAT[ii][1],
        coin_inst.COINCIDENCE_BIAS_B_A              = CHAN_DELAY_MAT[ii][0];

        assign coin_pair_data[ii] = {ii[PAIR_WIDTH-1:0],coin_odata_B[ii],coin_odata_A[ii]}; 
    end      
endgenerate

//=======================================================
//  ROTATING BUS
//=======================================================
wire [PAIR_DATA_WIDTH-1:0] rotation_data_out;
wire rotation_data_out_en;
rotating_bus
#(
    .PAIR_DATA_WIDTH( PAIR_DATA_WIDTH),
    .PAIR_WIDTH( PAIR_WIDTH),
    .PAIR_NUM( PAIR_NUM ),
    .DETECTOR_DATA_WIDTH( DETECTOR_DATA_WIDTH)
) rotating_bus_inst
(
    .clk(clk_200M),
    .rst(~rst_n),
    .coin_pair_data(coin_pair_data),
    .coin_pair_data_en(coin_odata_en),

    .rotation_data_out(rotation_data_out),	
    .rotation_data_out_en(rotation_data_out_en)
);

assign coincidence_data     = rotation_data_out;
assign coincidence_data_en  = rotation_data_out_en;

endmodule