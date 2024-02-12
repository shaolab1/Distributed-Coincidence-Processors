module uart_tx #(
    parameter CLK_FREQ = 32'd50_000_000,
    parameter BUAD_RATE  = 24'd115200,
    parameter DATA_WIDTH = 4'd8,
    parameter STOP_WIDTH = 2'd1)
(
    clk,
    rst_n,
    tx_en,
    data_tx,
    txd,
    tx_done,
    busy
);
    input clk, rst_n, tx_en; 
    input [7:0] data_tx; // Up to 8 bits
    output reg txd, tx_done, busy;

    // Cache data
    localparam TOTAL_BITS = DATA_WIDTH + STOP_WIDTH + 2; // 2 start (2'b10) + 5-8 data bits + 1-2 stop bits
    localparam STOP_BITS = {STOP_WIDTH{1'b1}},
               START_BITS = 2'b01; // Inversed so that LSB be sent first

    reg en; reg [TOTAL_BITS:0] data; reg [3:0] tx_cnt;
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            en <= 1'b0;
            data <= 8'b0;
        end
        else begin
            if(tx_en) begin
                en <= 1'b1;
                data <= {1'b1,STOP_BITS, data_tx[DATA_WIDTH-1:0],START_BITS}; 
                // LSB first, the highes 1'b1 is an extra bit to simplify the tx code
            end
            else if(tx_cnt == TOTAL_BITS) begin
                en <= 1'b0;
            end
            else 
                en <= en;
        end
    end

    localparam BUAD_CNT = CLK_FREQ / BUAD_RATE;
    reg [15:0] br_cnt; reg tx_clk;
    // Generate TX clock
    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            br_cnt <= 16'h0;
            tx_clk <= 1'b0;
        end 
        else begin
            if(en)
                br_cnt <= (br_cnt == BUAD_CNT - 1'b1) ? 16'b0 : (br_cnt + 1'b1);
            else
                br_cnt <= 16'h0;

            tx_clk <= (br_cnt == 16'h1) ? 1'b1 : 1'b0; // Generate one-period high tx_clk
        end
    end

    // Generate data transmit counter
    always @(posedge clk , negedge rst_n) begin
        if (~rst_n) begin
            tx_cnt <= 4'b0;
        end 
        else begin
            if(tx_cnt == TOTAL_BITS)
                tx_cnt <= 4'd0;
            else if(tx_clk) 
                tx_cnt <= tx_cnt + 1'b1;
            else    
                tx_cnt <= tx_cnt;
        end
    end

    // Transmit data
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) 
            txd <= 1'b1;
        else
            txd <= tx_clk ? data[tx_cnt] : txd;
            // if(tx_cnt < TOTAL_BITS)
            //     txd <= tx_clk ? data[tx_cnt] : txd;
            // else
            //     txd <= txd;
    end

    // Control transmit status
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
           busy <= 1'b0;
           tx_done <= 1'b0;
        end
        else begin
            busy <= en ? 1'b1 : 1'b0;
            tx_done <= (tx_cnt == TOTAL_BITS) ? 1'b1 : 1'b0;
        end
    end
endmodule