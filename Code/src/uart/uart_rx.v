/*
    UART RX module
    Capable of setting working frequency, buad rate, data width, stop width
    Oversampling each bit to gain robustness

    A small issue: if an unstable bit occurs during receiving whole bits, the sampling stops.
    But if master continues sending and another negative edge happens, it will re-start sampling
    and eventually outpu a fault data byte. This could destroy all following bytes if rxd is continuous
    without gap. To avoid this, Master needs to mannually stop tx for a certain time (> 12 Tbit) 
*/

module uart_rx #(
    parameter CLK_FREQ = 32'd50_000_000,
    parameter BUAD_RATE  = 24'd115200,
    parameter DATA_WIDTH = 4'd8,
    parameter STOP_WIDTH = 2'd1,
    parameter SP_NUM_PER_BIT = 8'd8, 
    // Total sampling times per bit, set according to CLK_FREQ and BUAD_RATE, avoid too large numbers
    parameter SP_NUM = 8'd4 
    // Sampling times in the sampling window for data recognition and error detection, must be a EVEN number
) (
    clk,
    rst_n,
    
    rxd,

    data_rx,
    rx_done,
    error
);

input clk, rst_n, rxd;
output reg [7:0] data_rx;
output reg rx_done, error;

// Sync & edge detection
reg [3:0] rxd_tmp; wire nedge; wire rxd_i; // rxd_i, internal rxd which has been sync
always @(posedge clk or negedge rst_n) begin
    rxd_tmp <= ~rst_n ? 4'hF : {rxd_tmp[2:0], rxd};
end
assign nedge = rxd_tmp[3] && !rxd_tmp[2];
assign rxd_i = rxd_tmp[3];

//****************Clock generation****************//
localparam FULL_WIDTH = DATA_WIDTH + STOP_WIDTH + 1'b1; // 1'b1 for start bit, up to 11 bits
localparam SP_CK_DIVIDER = CLK_FREQ / BUAD_RATE / SP_NUM_PER_BIT; //Sampling clock divider
localparam MAX_SP_TIMES = FULL_WIDTH * SP_NUM_PER_BIT; // Maximal sampling times
reg sp_en; // Sampling enable signal
reg [15:0] sp_ck_cnt; // Sampling clock counter
reg sp_ck; // Sampling clock signal
reg [7:0] sp_cnt; // Sampling times counter
// reg [3:0] bit_cnt; // Bit number counter
wire last_sample;

// Sampling enable generation
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) 
        sp_en <= 1'b0;
    else if(nedge) // START bit detected
        sp_en <= 1'b1;
    else if(last_sample | error) // Sampling done or Bit error, stop sampling
        sp_en <= 1'b0;
    else 
        sp_en <= sp_en;
end

// Sampling clock generation
always @(posedge clk or negedge rst_n) begin
   if (~rst_n) begin
        sp_ck_cnt <= 16'h0; 
        sp_ck <= 1'b0;
   end 
   else begin
        if(sp_en)
            sp_ck_cnt <= (sp_ck_cnt == SP_CK_DIVIDER - 1'b1) ? 16'h0 : (sp_ck_cnt + 1'b1); 
        else
            sp_ck_cnt <= 16'h0;

        sp_ck <= (sp_ck_cnt == SP_CK_DIVIDER - 1'b1) ? 1'b1 : 1'b0;         
   end 
end

// Record sampling times in each bit
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        sp_cnt <= 8'd0;
    else begin
        if(sp_ck) begin
            sp_cnt <= (sp_cnt == MAX_SP_TIMES - 1'b1) ? 8'd0 : (sp_cnt + 1'b1);  
        end  
        else if(error)
            sp_cnt <= 8'd0;
        else 
            sp_cnt <= sp_cnt;
    end
end

assign last_sample = sp_ck && (sp_cnt == MAX_SP_TIMES - 1'b1);

//****************Sampling****************//

// Get the first and last sampling position in each rx bit
localparam SP_HEAD_B0 = (SP_NUM_PER_BIT - SP_NUM) >> 1'b1,
           SP_END_B0 = SP_HEAD_B0 + SP_NUM - 1'b1,
           SP_HEAD_B1 = SP_HEAD_B0 + SP_NUM_PER_BIT,
           SP_END_B1 = SP_HEAD_B1 + SP_NUM - 1'b1,
           SP_HEAD_B2 = SP_HEAD_B1 + SP_NUM_PER_BIT,
           SP_END_B2 = SP_HEAD_B2 + SP_NUM - 1'b1,
           SP_HEAD_B3 = SP_HEAD_B2 + SP_NUM_PER_BIT,
           SP_END_B3 = SP_HEAD_B3 + SP_NUM - 1'b1,
           SP_HEAD_B4 = SP_HEAD_B3 + SP_NUM_PER_BIT,
           SP_END_B4 = SP_HEAD_B4 + SP_NUM - 1'b1,
           SP_HEAD_B5= SP_HEAD_B4 + SP_NUM_PER_BIT,
           SP_END_B5 = SP_HEAD_B5 + SP_NUM - 1'b1,
           SP_HEAD_B6 = SP_HEAD_B5 + SP_NUM_PER_BIT,
           SP_END_B6 = SP_HEAD_B6 + SP_NUM - 1'b1,
           SP_HEAD_B7 = SP_HEAD_B6 + SP_NUM_PER_BIT,
           SP_END_B7 = SP_HEAD_B7 + SP_NUM - 1'b1,
           SP_HEAD_B8 = SP_HEAD_B7 + SP_NUM_PER_BIT,
           SP_END_B8 = SP_HEAD_B8 + SP_NUM - 1'b1,
           SP_HEAD_B9 = SP_HEAD_B8 + SP_NUM_PER_BIT,
           SP_END_B9 = SP_HEAD_B9 + SP_NUM - 1'b1,
           SP_HEAD_B10 = SP_HEAD_B9 + SP_NUM_PER_BIT,
           SP_END_B10 = SP_HEAD_B10 + SP_NUM - 1'b1;

// Multiple sampling data
reg [2:0] data_sp [10 : 0]; 
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        data_sp[0] <= 3'd0; data_sp[1] <= 3'd0; data_sp[2] <= 3'd0; data_sp[3] <= 3'd0;
        data_sp[4] <= 3'd0; data_sp[5] <= 3'd0; data_sp[6] <= 3'd0; data_sp[7] <= 3'd0; 
        data_sp[8] <= 3'd0; data_sp[9] <= 3'd0; data_sp[10] <= 3'd0; 
    end
    else begin
        if(sp_ck)
            if(sp_cnt == 8'd0) begin
                data_sp[0] <=  3'd0; data_sp[1] <=  3'd0; data_sp[2] <=  3'd0; data_sp[3] <=  3'd0;
                data_sp[4] <=  3'd0; data_sp[5] <=  3'd0; data_sp[6] <=  3'd0; data_sp[7] <=  3'd0; 
                data_sp[8] <=  3'd0; data_sp[9] <=  3'd0; data_sp[10] <=  3'd0;    
            end
            else if((sp_cnt >= SP_HEAD_B0) && (sp_cnt <= SP_END_B0))
                data_sp[0] <=  data_sp[0] + rxd_i;
            else if((sp_cnt >= SP_HEAD_B1) && (sp_cnt <= SP_END_B1))
                data_sp[1] <=  data_sp[1] + rxd_i;
            else if((sp_cnt >= SP_HEAD_B2) && (sp_cnt <= SP_END_B2))
                data_sp[2] <=  data_sp[2] + rxd_i;
            else if((sp_cnt >= SP_HEAD_B3) && (sp_cnt <= SP_END_B3))
                data_sp[3] <=  data_sp[3] + rxd_i;
            else if((sp_cnt >= SP_HEAD_B4) && (sp_cnt <= SP_END_B4))
                data_sp[4] <=  data_sp[4] + rxd_i;
            else if((sp_cnt >= SP_HEAD_B5) && (sp_cnt <= SP_END_B5))
                data_sp[5] <=  data_sp[5] + rxd_i;
            else if((sp_cnt >= SP_HEAD_B6) && (sp_cnt <= SP_END_B6))
                data_sp[6] <=  data_sp[6] + rxd_i;
            else if((sp_cnt >= SP_HEAD_B7) && (sp_cnt <= SP_END_B7))
                data_sp[7] <=  data_sp[7] + rxd_i;
            else if((sp_cnt >= SP_HEAD_B8) && (sp_cnt <= SP_END_B8))
                data_sp[8] <=  data_sp[8] + rxd_i;
            else if((sp_cnt >= SP_HEAD_B9) && (sp_cnt <= SP_END_B9))
                data_sp[9] <=  data_sp[9] + rxd_i;
            else if((sp_cnt >= SP_HEAD_B10) && (sp_cnt <= SP_END_B10))
                data_sp[10] <=  data_sp[10] + rxd_i;
            else begin
                data_sp[0] <= data_sp[0]; data_sp[1] <= data_sp[1]; data_sp[2] <= data_sp[2]; data_sp[3] <= data_sp[3];
                data_sp[4] <= data_sp[4]; data_sp[5] <= data_sp[5]; data_sp[6] <= data_sp[6]; data_sp[7] <= data_sp[7]; 
                data_sp[8] <= data_sp[8]; data_sp[9] <= data_sp[9]; data_sp[10] <= data_sp[10]; 
            end
        else begin
            data_sp[0] <= data_sp[0]; data_sp[1] <= data_sp[1]; data_sp[2] <= data_sp[2]; data_sp[3] <= data_sp[3];
            data_sp[4] <= data_sp[4]; data_sp[5] <= data_sp[5]; data_sp[6] <= data_sp[6]; data_sp[7] <= data_sp[7]; 
            data_sp[8] <= data_sp[8]; data_sp[9] <= data_sp[9]; data_sp[10] <= data_sp[10]; 
        end
    end
end

// Check if any bits are not stable
localparam  SP_NUM_HF = (SP_NUM >> 1'b1), // If data_sp[X] = SP_NUM/2 , then rxd is not stable --> error
            ERR_B0 = SP_NUM_PER_BIT - 1'b1,
            ERR_B1 = ERR_B0 + SP_NUM_PER_BIT,
            ERR_B2 = ERR_B1 + SP_NUM_PER_BIT,
            ERR_B3 = ERR_B2 + SP_NUM_PER_BIT,
            ERR_B4 = ERR_B3 + SP_NUM_PER_BIT,
            ERR_B5 = ERR_B4 + SP_NUM_PER_BIT,
            ERR_B6 = ERR_B5 + SP_NUM_PER_BIT,
            ERR_B7 = ERR_B6 + SP_NUM_PER_BIT,
            ERR_B8 = ERR_B7 + SP_NUM_PER_BIT;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        error <= 1'b0;
    else begin
        if(sp_ck)
            if(sp_cnt == 8'd0)
                error <= 1'b0;
            else if(sp_cnt == ERR_B0)
                error <= (data_sp[0] == SP_NUM_HF) ? 1'b1 : 1'b0;
            else if(sp_cnt == ERR_B1)
                error <= (data_sp[1] == SP_NUM_HF) ? 1'b1 : 1'b0;
            else if(sp_cnt == ERR_B2)
                error <= (data_sp[2] == SP_NUM_HF) ? 1'b1 : 1'b0;
            else if(sp_cnt == ERR_B3)
                error <= (data_sp[3] == SP_NUM_HF) ? 1'b1 : 1'b0;
            else if(sp_cnt == ERR_B4)
                error <= (data_sp[4] == SP_NUM_HF) ? 1'b1 : 1'b0;
            else if(sp_cnt == ERR_B5)
                error <= (data_sp[5] == SP_NUM_HF) ? 1'b1 : 1'b0;
            else if(sp_cnt == ERR_B6)
                error <= (data_sp[6] == SP_NUM_HF) ? 1'b1 : 1'b0;
            else if(sp_cnt == ERR_B7)
                error <= (data_sp[7] == SP_NUM_HF) ? 1'b1 : 1'b0;    
            else if(sp_cnt == ERR_B8)
                error <= (data_sp[8] == SP_NUM_HF) ? 1'b1 : 1'b0;    
            else
                error <= 1'b0;
        else
            error <= 1'b0;
    end
end

//****************Output data****************//
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
       data_rx <= 8'd0;
       rx_done <= 1'b0;
    end
    else begin
        if(last_sample) begin
            data_rx[0] <= (data_sp[1] > SP_NUM_HF) ? 1'b1 : 1'b0; // if the sum of SP_NUM times sampling > SP_NUM/2
            data_rx[1] <= (data_sp[2] > SP_NUM_HF) ? 1'b1 : 1'b0; // then it's high, otherwise it's low 
            data_rx[2] <= (data_sp[3] > SP_NUM_HF) ? 1'b1 : 1'b0;
            data_rx[3] <= (data_sp[4] > SP_NUM_HF) ? 1'b1 : 1'b0;
            data_rx[4] <= (data_sp[5] > SP_NUM_HF) ? 1'b1 : 1'b0;
            data_rx[5] <= (data_sp[6] > SP_NUM_HF) ? 1'b1 : 1'b0;
            data_rx[6] <= (data_sp[7] > SP_NUM_HF) ? 1'b1 : 1'b0;
            data_rx[7] <= (data_sp[8] > SP_NUM_HF) ? 1'b1 : 1'b0;

            rx_done <= 1'b1;
        end
        else begin
            data_rx <= data_rx;
            rx_done <= 1'b0;
        end   
    end        
end
endmodule