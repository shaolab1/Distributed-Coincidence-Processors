`include "openDCP.sv"
`include "common/function_log2.v"
`define __LOG2__
`include "uart/uart_tx_warp.sv"
`include "uart/uart_rx.v"

module openDCP_test(
    OSC_100_BANKX,
    rst_n,

    rxd,
    txd
);
//=======================================================
//  Parameter
//=======================================================
    parameter LVDS_CHAN_NUM = 8'd32;
    parameter CHANNEL_TIMING_WIDTH = 8'd32 + 8'd16 + 8'd8;
    parameter TDC_POS = 16*4, TDC_COARSE_POS = 16*4+8, TDC_COARSE_WIDTH = 24, TDC_WIDTH = 32;
    parameter P_WIDTH = 8'd16, E_WIDTH = 8'd16, BOARDID_WIDTH = 8'd8;
    parameter DETECTOR_DATA_WIDTH = P_WIDTH*2 + E_WIDTH*2 + CHANNEL_TIMING_WIDTH + BOARDID_WIDTH;
    parameter PAIR_WIDTH = 8'd16; parameter PAIR_DATA_WIDTH = DETECTOR_DATA_WIDTH*2 + PAIR_WIDTH;

//=======================================================
//  Ports
//=======================================================
    input                   OSC_100_BANKX;
	input      [3:0]        rst_n;
    input                   rxd;
    output                  txd;

//=======================================================
//  Sync Async Reset
//=======================================================
	wire rst_n_e = & rst_n; reg [1:0] rstn_r; wire rstn_i;
    always @(posedge OSC_100_BANKX or negedge rst_n_e) 
        rstn_r <= ~rst_n_e ? 2'b00 : {rstn_r[0], 1'b1};

    assign rstn_i = rstn_r[1];

//=======================================================
//  Global PLL
//=======================================================
    wire clk_50M, clk_200M;
    pll_internal pll_internal_inst (
        .locked   (),   //  output,  width = 1,  locked.export
        .outclk_0 (clk_50M), //  output,  width = 1, outclk0.clk
        .outclk_1 (clk_200M), //  output,  width = 1, outclk1.clk
        
        .refclk   (OSC_100_BANKX),   //   input,  width = 1,  refclk.clk
        .rst      ()       //   input,  width = 1,   reset.reset
    );

//=======================================================
//  Host control
//=======================================================
////////////UART RX////////////
    wire [7:0] data_rx; wire rx_done;
    uart_rx uart_rx_inst(
        .clk(clk_200M),
        .rst_n(rstn_i),
        
        .rxd(rxd),

        .data_rx(data_rx),
        .rx_done(rx_done),
        .error()
    );
    defparam
        uart_rx_inst.CLK_FREQ       = 32'd200_000_000,
        uart_rx_inst.BUAD_RATE      = 24'd921600,
        uart_rx_inst.DATA_WIDTH     = 4'd8,
        uart_rx_inst.STOP_WIDTH     = 2'd1;

////////////Decode////////////
    reg [7:0] timing_window;  reg tw_en;
    reg [1:0] test_mode;
    always @(posedge clk_200M or negedge rstn_i ) begin
        if(~rstn_i) begin
            tw_en <= 1'b0;
            timing_window <= 8'd10;
            test_mode <= 2'b00;
        end
        else begin
            if(data_rx == 8'hFF)
                tw_en <= 1'b1;

            if(tw_en & rx_done) begin
                timing_window <= data_rx;
                tw_en <= 1'b0;
            end

            if(data_rx == 8'hEF)
                test_mode <= 2'b01;
            else if (data_rx == 8'hEE)
                test_mode <= 2'b10;
            else if (data_rx == 8'hE0)
                test_mode <= 2'b00;
            else
                test_mode <= test_mode;
        end
    end

//=======================================================
//  Coincidence Core
//=======================================================
    wire [DETECTOR_DATA_WIDTH-1:0] event_data [LVDS_CHAN_NUM-1:0];
    wire [LVDS_CHAN_NUM-1:0] event_data_en;
    wire [PAIR_DATA_WIDTH-1:0] coin_data;
    wire coin_data_en;
    openDCP openDCP_inst(
        .clk_200M(clk_200M),
        .rst_n(rstn_i),

        .test_mode(test_mode),
        .timing_window(timing_window),
        
        .event_data(event_data),
        .event_data_en(event_data_en),

        .coincidence_data(coin_data),
        .coincidence_data_en(coin_data_en)
    );
    defparam
        openDCP_inst.LVDS_CHAN_NUM          = LVDS_CHAN_NUM,
        openDCP_inst.DETECTOR_DATA_WIDTH    = DETECTOR_DATA_WIDTH,
        openDCP_inst.PAIR_DATA_WIDTH        = PAIR_DATA_WIDTH,
        openDCP_inst.PAIR_WIDTH             = PAIR_WIDTH;

//=======================================================
//  Data Upload via UART
//=======================================================
    uart_tx_warp utw_inst(
        .clk(clk_200M),
        .rst_n(rstn_i),

        .clk_data(clk_200M),
        .data({coin_data[PAIR_DATA_WIDTH-1 -: PAIR_WIDTH],coin_data[(TDC_POS+DETECTOR_DATA_WIDTH) +: 32],coin_data[TDC_POS +: 32],timing_window}),
        .data_en(coin_data_en),

        .txd(txd)
    );
    defparam
        utw_inst.CLK_FREQ       = 32'd200_000_000,
        utw_inst.BUAD_RATE      = 24'd921600,
        utw_inst.DATA_WIDTH     = 4'd8,
        utw_inst.STOP_WIDTH     = 2'd1,
        utw_inst.INDATA_WIDTH   = 8+PAIR_WIDTH+TDC_WIDTH*2,
        utw_inst.FIFO_DEPTH     = 1024,
        utw_inst.TX_HEADER      = 8'hFF,
        utw_inst.TX_ENDER       = 8'hEE;

endmodule