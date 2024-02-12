module rotating_bus
#(
	parameter PAIR_DATA_WIDTH = 20,
    parameter PAIR_WIDTH = 8,
	parameter PAIR_NUM = 256,
	parameter DETECTOR_DATA_WIDTH = 128
)
(
	input clk,
	input rst,
    input [PAIR_DATA_WIDTH-1:0] coin_pair_data [PAIR_NUM-1:0],
    input [PAIR_NUM-1:0] coin_pair_data_en,

	output reg [PAIR_DATA_WIDTH-1:0] rotation_data_out,	
	output reg rotation_data_out_en
);

//=======================================================
//  BUFFER before Rotating BUS
//=======================================================

reg [PAIR_NUM-1:0] ROTATION_BUFFER_rdack;
wire [PAIR_NUM-1:0] ROTATION_BUFFER_full;
wire [PAIR_NUM-1:0] ROTATION_BUFFER_empty;
wire [PAIR_DATA_WIDTH-1:0] ROTATION_BUFFER_q [PAIR_NUM-1:0];


genvar ii_buffer;
generate
for(ii_buffer=0; ii_buffer<PAIR_NUM; ii_buffer++) begin:pair_buffer
/*
scfifo	buffer (
            .clock (clk),
			.data (coin_pair_data[ii_buffer]),	
			.rdreq (ROTATION_BUFFER_rdack[ii_buffer]),
			.wrreq (coin_pair_data_en[ii_buffer]),
			.empty (ROTATION_BUFFER_empty[ii_buffer]),
			.full (ROTATION_BUFFER_full[ii_buffer]),
			.q(ROTATION_BUFFER_q[ii_buffer]),
			.aclr (),
			.almost_empty (),
			.almost_full (),
			.eccstatus (),
			.sclr (rst),
			.usedw ());
	defparam
		buffer.add_ram_output_register = "ON",
      buffer.intended_device_family = "Arria V",
		buffer.lpm_numwords = 4,
		buffer.lpm_showahead = "ON",
		buffer.lpm_type = "scfifo",
		buffer.lpm_width = PAIR_DATA_WIDTH,
		buffer.lpm_widthu = 2,
		buffer.overflow_checking = "ON",
		buffer.underflow_checking = "ON",
		buffer.use_eab = "ON";
*/		
		
dcfifo	buffer (
            .data (coin_pair_data[ii_buffer]),
            .rdclk (clk),
            .rdreq (ROTATION_BUFFER_rdack[ii_buffer]),
            .wrclk (clk),
            .wrreq (coin_pair_data_en[ii_buffer]),
            .q (ROTATION_BUFFER_q[ii_buffer]),
            .rdempty (ROTATION_BUFFER_empty[ii_buffer]),
            .wrfull (ROTATION_BUFFER_full[ii_buffer]),
            .aclr (rst),
            .eccstatus (),
            .rdfull (),
            .rdusedw (),
            .wrempty (),
            .wrusedw ());
	defparam
//		buffer.intended_device_family = "Arria V",
//		buffer.lpm_hint = "RAM_BLOCK_TYPE=MLAB",
		buffer.lpm_numwords = 4,
		buffer.lpm_showahead = "ON",
		buffer.lpm_type = "dcfifo",
		buffer.lpm_width = PAIR_DATA_WIDTH,
		buffer.lpm_widthu = 2,
		buffer.overflow_checking = "ON",
		buffer.rdsync_delaypipe = 9,
		buffer.underflow_checking = "ON",
		buffer.use_eab = "ON",
		buffer.wrsync_delaypipe = 9;		
		
		
		
end
endgenerate

reg [PAIR_DATA_WIDTH:0] rotating_bus [PAIR_NUM:0];

int ii_rotation;
	always@(posedge clk or posedge rst) begin
		if(rst)begin
			ROTATION_BUFFER_rdack <= 0;
			rotation_data_out_en <= 0;
			rotation_data_out <=0 ;
			for (ii_rotation=0; ii_rotation<=PAIR_NUM; ii_rotation=ii_rotation+1) begin
				rotating_bus[ii_rotation][PAIR_DATA_WIDTH]<=0;
				rotating_bus[ii_rotation][(PAIR_DATA_WIDTH-1):(PAIR_DATA_WIDTH-PAIR_WIDTH)]<=ii_rotation[PAIR_WIDTH-1:0];
				rotating_bus[ii_rotation][DETECTOR_DATA_WIDTH*2-1:0]<=0;
			end
		end
		else begin
			
			// For carts from 0 to PAIR_NUM-1
			for (ii_rotation=0; ii_rotation<PAIR_NUM; ii_rotation=ii_rotation+1) begin
				if(	~ROTATION_BUFFER_empty[ii_rotation] ) begin
				// If there are new events on buffer i
					if( rotating_bus[ii_rotation+1][(PAIR_DATA_WIDTH-1):(PAIR_DATA_WIDTH-PAIR_WIDTH)] == ii_rotation) begin
					// If next rotates to cart i
						if( ~rotating_bus[ii_rotation+1][PAIR_DATA_WIDTH] ) begin
						// If next cart is not taken,
							//store this new event in this cart.
							rotating_bus[ii_rotation] <= {1'b1,ROTATION_BUFFER_q[(ii_rotation)]};
							// send acknowledge signal.
							ROTATION_BUFFER_rdack[ii_rotation] <= 1;
						end
						else begin
							// Rotate as usual and shut down acknowledge signal.
							rotating_bus[ii_rotation] <= rotating_bus[(ii_rotation+1)];
							ROTATION_BUFFER_rdack[ii_rotation] <= 0;
						end
					end
					else begin
					// If not rotates to cart i
						// Rotate as usual and shut down acknowledge signal.
						rotating_bus[ii_rotation] <= rotating_bus[(ii_rotation+1)];
						ROTATION_BUFFER_rdack[ii_rotation] <= 0;
					end
				end
				else begin
					// Rotate as usual and shut down acknowledge signal.
					rotating_bus[ii_rotation] <= rotating_bus[(ii_rotation+1)];
					ROTATION_BUFFER_rdack[ii_rotation] <= 0;
				end
			end

			// For cart (PAIR_NUM-1)
			// If this cart has event data, output it and clear the cart
			if(rotating_bus[0][PAIR_DATA_WIDTH]) begin
				rotation_data_out <= rotating_bus[0][PAIR_DATA_WIDTH-1:0];
				rotation_data_out_en <= 1;
				rotating_bus[PAIR_NUM][PAIR_DATA_WIDTH] <= 0;
				rotating_bus[PAIR_NUM][PAIR_DATA_WIDTH-1:0] <= rotating_bus[0][PAIR_DATA_WIDTH-1:0];
			end
			else begin
				rotation_data_out_en <= 0;
				rotating_bus[PAIR_NUM] <= rotating_bus[0];
			end
		end
	end

endmodule