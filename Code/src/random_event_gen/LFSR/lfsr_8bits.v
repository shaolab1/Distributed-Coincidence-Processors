module lfsr_8bits(
    clk, 
    rst_n, 
    en,
    seed, 
    q
);
    input clk, rst_n, en;
    input [7:0] seed;
    output reg [7:0] q;

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n)
            q <= seed; // can be anything except zero
        else if(en)
            q <= {q[6:0], q[7] ^ q[5] ^ q[4] ^ q[3]}; // polynomial for maximal LFSR
    end

endmodule