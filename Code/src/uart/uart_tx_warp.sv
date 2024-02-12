`include "uart_tx.v"
`ifndef __LOG2__
    `define __LOG2__
    `include "common/function_log2.v"
`endif

module uart_tx_warp(
    clk,
    rst_n,

    clk_data,
    data,
    data_en,

    txd
);

//=======================================================
//  PARAMETER declarations
//=======================================================
    parameter   CLK_FREQ = 32'd50_000_000,
                BUAD_RATE  = 24'd115200,
                DATA_WIDTH = 4'd8,
                STOP_WIDTH = 2'd1;
    parameter   INDATA_WIDTH = 32,
                FIFO_DEPTH   = 128,
                TX_HEADER    = 8'hFF,
                TX_ENDER     = 8'hEE;
    localparam  BYTE_NUM = INDATA_WIDTH / DATA_WIDTH;

//=======================================================
//  Port declarations
//=======================================================
    input clk; // clock for uart
    input rst_n;

    input clk_data; // clock for data input
    input [INDATA_WIDTH-1:0] data;
    input data_en;

    output txd;

//=======================================================
//  Buffer
//=======================================================
    wire [INDATA_WIDTH-1:0] dcfifo_q; wire dcfifo_rdempty, dcfifo_wrfull, dcfifo_rdreq;
    dcfifo	buffer (
            .data (data ),
            .rdclk (clk),
            .rdreq (dcfifo_rdreq),
            .wrclk (clk_data),
            .wrreq (data_en & ~dcfifo_wrfull),
            .q (dcfifo_q),
            .rdempty (dcfifo_rdempty),
            .wrfull (dcfifo_wrfull),
            .aclr (~rst_n ),
            .eccstatus (),
            .rdfull (),
            .rdusedw (),
            .wrempty (),
            .wrusedw ());
	defparam
        buffer.intended_device_family = "Stratix IV",
		buffer.lpm_hint = "RAM_BLOCK_TYPE=MLAB",
		buffer.lpm_numwords = FIFO_DEPTH,
		buffer.lpm_showahead = "ON",
		buffer.lpm_type = "dcfifo",
		buffer.lpm_width = INDATA_WIDTH,
		buffer.lpm_widthu = log2(FIFO_DEPTH),
		buffer.overflow_checking = "ON",
		buffer.rdsync_delaypipe = 4,
		buffer.underflow_checking = "ON",
		buffer.use_eab = "ON",
		buffer.wrsync_delaypipe = 4;

//=======================================================
//  Control
//=======================================================
    // FIFO read
    reg [3:0] UART_FSM;
    localparam  IDLE    = 4'd1, 
                HEADER  = 4'd2,
                BODY    = 4'd4,
                ENDER   = 4'd8;

    reg tx_en; reg [DATA_WIDTH-1:0] tx_data;
    wire tx_done, tx_busy; reg [15:0] cnt; reg rd_en;
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin 
            UART_FSM <= IDLE;
            rd_en <= 1'b0;
            cnt <= 16'd0;
            tx_en <= 1'b0;
            tx_data <= {DATA_WIDTH{1'b0}};
        end
        else begin
            case(UART_FSM)
                IDLE: begin
                    cnt <= 16'd0;
                    tx_en <= 1'b0;
 
                    if(~tx_busy & cnt == 16'd0 & ~dcfifo_rdempty) begin // uart tx available
                        rd_en <= 1'b1;                        
                        UART_FSM <= HEADER;
                    end
                    else 
                        rd_en <= 1'b0;                        
                end
                HEADER: begin
                    rd_en <= 1'b0;
                    tx_en <= 1'b1;
                    tx_data <= TX_HEADER;
                    UART_FSM <= BODY;
                end
                BODY: begin
                    if(tx_done) begin
                        cnt <= cnt + 1'b1;
                        tx_en <= 1'b1;
                        tx_data <= dcfifo_q[cnt*DATA_WIDTH +: DATA_WIDTH];
                    end
                    else 
                        tx_en <= 1'b0;

                    UART_FSM <= cnt == BYTE_NUM ? ENDER : BODY;                    
                end
                ENDER: begin 
                    if(tx_done) begin
                        cnt <= cnt + 1'b1;
                        tx_en <= 1'b1;
                        tx_data <= TX_ENDER;
                    end
                    else
                        tx_en <= 1'b0; 

                    UART_FSM <= (cnt == BYTE_NUM + 1'b1) ? IDLE: ENDER;
                end
                default: UART_FSM <= IDLE;
            endcase
        end 
    end
    assign dcfifo_rdreq = rd_en;

////=======================================================
////  UART TX
////=======================================================
    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BUAD_RATE (BUAD_RATE),
        .DATA_WIDTH(DATA_WIDTH),
        .STOP_WIDTH(STOP_WIDTH)
    ) uart_tx_inst(
        .clk(clk),
        .rst_n(rst_n),
        .tx_en(tx_en),
        .data_tx(tx_data),
        .txd(txd),
        .tx_done(tx_done),
        .busy(tx_busy)
    );
endmodule