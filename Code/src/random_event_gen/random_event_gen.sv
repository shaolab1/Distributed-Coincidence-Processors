`include "./LFSR/lfsr_8bits.v"

module random_event_gen(
    clk,
    rst_n,

    mode,
    en,

    event_data,
    event_data_en
);

//=======================================================
//  PARAMETER declarations
//=======================================================
    parameter DETECTOR_DATA_WIDTH = 128;
    parameter LVDS_CHAN_NUM = 32;

//=======================================================
//  Ports
//=======================================================
    input clk, rst_n, en; input [1:0] mode;
    output reg [DETECTOR_DATA_WIDTH-1:0] event_data [LVDS_CHAN_NUM-1:0];
    output reg [LVDS_CHAN_NUM-1:0] event_data_en;

//=======================================================
//  Random Event Generate
//=======================================================
    reg [7:0] fine_time [LVDS_CHAN_NUM-1:0];
    genvar ii;
    generate
        for(ii = 0; ii < LVDS_CHAN_NUM; ii++) begin: lfsr_8bits
            lfsr_8bits lfsr_8bits_inst(
                .clk(clk), 
                .rst_n(rst_n), 
                .en(en),
                .seed(ii[7:0]+1'b1), 
                .q(fine_time[ii])
            );

            always @(posedge clk or negedge rst_n) begin
                if(~rst_n) begin
                    event_data[ii] <= {DETECTOR_DATA_WIDTH{1'b0}};
                    event_data_en[ii] <= 1'b0;
                end
                else begin
                    if(mode == 2'b01) 
                       event_data[ii] <= {8'hdc, 8'hba, 8'h98, 8'h76, 8'h54, 8'h32, 8'h10, fine_time[ii], 8'hfe, 8'hdc, 8'hba, 8'h98, 8'h76, 8'h54, 8'h32, 8'h10}; 
                    else
                        event_data[ii] <= {8'hdc, 8'hba, 8'h98, 8'h76, 8'h54, 8'h32, fine_time[ii], 8'h10, 8'hfe, 8'hdc, 8'hba, 8'h98, 8'h76, 8'h54, 8'h32, 8'h10};
            
                    event_data_en[ii] <= en;
                end
            end
        end
    endgenerate

endmodule