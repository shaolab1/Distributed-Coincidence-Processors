`define COINCIDENCE_BUFFER_DEPTH 2

module coincidence_buffer(
	clk,
	rst,
	
	idata,
	idata_en,

	odata_req,	
	buffer_full,
	buffer_empty,
	odata
);

parameter COINCIDENCE_BUFFER_WIDTH = 1024;

input clk;
input rst;

input [COINCIDENCE_BUFFER_WIDTH-1:0] idata;
input idata_en;

input odata_req;
output buffer_full;
output buffer_empty;
output [COINCIDENCE_BUFFER_WIDTH-1:0] odata;

localparam BUFFER_FIFO_DATAW_WIDTH = COINCIDENCE_BUFFER_WIDTH;
localparam	BUFFER_FIFO_USEDW_WIDTH = log2(`COINCIDENCE_BUFFER_DEPTH);
localparam	BUFFER_FIFO_DATAR_WIDTH = BUFFER_FIFO_DATAW_WIDTH;
localparam	BUFFER_FIFO_USEDR_WIDTH = BUFFER_FIFO_USEDW_WIDTH;

reg [COINCIDENCE_BUFFER_WIDTH-1:0] BUFFER_fifo_data,BUFFER_fifo_data_buf;
reg BUFFER_fifo_wrreq,BUFFER_fifo_wrreq_buf;
wire BUFFER_fifo_reset = rst;
wire BUFFER_fifo_rdclk = clk;
wire BUFFER_fifo_rdack = odata_req;

wire [COINCIDENCE_BUFFER_WIDTH-1:0]  BUFFER_fifo_q;
assign odata = BUFFER_fifo_q;
wire BUFFER_fifo_rdempty;
wire BUFFER_fifo_wrfull;
assign buffer_empty = BUFFER_fifo_rdempty;
assign buffer_full = BUFFER_fifo_wrfull;
/*
scfifo	buffer (
            .clock (BUFFER_fifo_rdclk),
			.data (BUFFER_fifo_data),	
			.rdreq (BUFFER_fifo_rdack),
			.wrreq (BUFFER_fifo_wrreq),
			.empty (BUFFER_fifo_rdempty),
			.full (BUFFER_fifo_wrfull),
			.q(BUFFER_fifo_q),
			.aclr (),
			.almost_empty (),
			.almost_full (),
			.eccstatus (),
			.sclr (BUFFER_fifo_reset),
			.usedw ());
	defparam
		buffer.add_ram_output_register = "ON",
        buffer.intended_device_family = "Cyclone V",
		buffer.lpm_numwords = `COINCIDENCE_BUFFER_DEPTH,
		buffer.lpm_showahead = "ON",
		buffer.lpm_type = "scfifo",
		buffer.lpm_width = BUFFER_FIFO_DATAW_WIDTH,
		buffer.lpm_widthu = BUFFER_FIFO_USEDW_WIDTH,
		buffer.overflow_checking = "OFF",
		buffer.underflow_checking = "OFF",
		buffer.use_eab = "ON";
*/

dcfifo	buffer (
            .data (BUFFER_fifo_data_buf),
            .rdclk (BUFFER_fifo_rdclk),
            .rdreq (BUFFER_fifo_rdack),
            .wrclk (BUFFER_fifo_rdclk),
            .wrreq (BUFFER_fifo_wrreq_buf),
            .q (BUFFER_fifo_q),
            .rdempty (BUFFER_fifo_rdempty),
            .wrfull (BUFFER_fifo_wrfull),
            .aclr (BUFFER_fifo_reset),
            .eccstatus (),
            .rdfull (),
            .rdusedw (),
            .wrempty (),
            .wrusedw ());
	defparam
		buffer.intended_device_family = "Stratix 10",
//		buffer.lpm_hint = "RAM_BLOCK_TYPE=MLAB",
		buffer.lpm_numwords = `COINCIDENCE_BUFFER_DEPTH,
		buffer.lpm_showahead = "OFF",
		buffer.lpm_type = "dcfifo",
		buffer.lpm_width = BUFFER_FIFO_DATAW_WIDTH,
		buffer.lpm_widthu = BUFFER_FIFO_USEDW_WIDTH,
		buffer.overflow_checking = "ON",
		buffer.rdsync_delaypipe = 9,
		buffer.underflow_checking = "ON",
		buffer.use_eab = "ON",
		buffer.wrsync_delaypipe = 9;
//		buffer.use_eab = "OFF";


//====================================================
//Send data to FIFO

always@(posedge clk or posedge rst)
begin	
	if(rst) begin
		BUFFER_fifo_wrreq <= 1'b0;
		BUFFER_fifo_wrreq_buf <= 1'b0;
	end
	else begin
		BUFFER_fifo_data <= idata;
		BUFFER_fifo_wrreq <= idata_en;	

		BUFFER_fifo_data_buf <= BUFFER_fifo_data;
		BUFFER_fifo_wrreq_buf <= BUFFER_fifo_wrreq;

	end
end	

endmodule