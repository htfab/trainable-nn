// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2022 Tamas Hubai

`default_nettype none

// testbench for the single neural_network module in network.v

module neural_network_tb ();

reg clk;
reg fp;
wire fp_out;
reg [`NUM_WIDTH-1:0] a0[`INPUT_SIZE-1:0];
wire [`NUM_WIDTH-1:0] a3[`OUTPUT_SIZE-1:0];
reg bp;
wire bp_out;
reg [`NUM_WIDTH-1:0] g3[`OUTPUT_SIZE-1:0];
reg wu;
reg [1:0] w_layer;
reg [`INDEX_WIDTH-1:0] w_i;
reg [`INDEX_WIDTH-1:0] w_j;
reg [`NUM_WIDTH-1:0] w_in;
wire [`NUM_WIDTH-1:0] w_out;

wire [`INPUT_SIZE*`NUM_WIDTH-1:0] a0_pk;
`PACK_ARRAY(`NUM_WIDTH, `INPUT_SIZE, a0, a0_pk)
wire [`OUTPUT_SIZE*`NUM_WIDTH-1:0] a3_pk;
`UNPACK_ARRAY(`NUM_WIDTH, `OUTPUT_SIZE, a3, a3_pk)
wire [`OUTPUT_SIZE*`NUM_WIDTH-1:0] g3_pk;
`PACK_ARRAY(`NUM_WIDTH, `OUTPUT_SIZE, g3, g3_pk)

neural_network dut (
    .clk,
    .fp,
    .fp_out,
    .a0_pk,
    .a3_pk,
    .bp,
    .bp_out,
    .g3_pk,
    .wu,
    .w_layer,
    .w_i,
    .w_j,
    .w_in,
    .w_out
);

wire [`NUM_WIDTH-1:0] a_test = a3[4];

generate genvar i; genvar j;

for (i=0; i<`INPUT_SIZE; i=i+1) begin
    for (j=0; j<`HIDDEN1_SIZE; j=j+1) begin
        initial begin
            dut.g_syn01_o[i].g_syn01_i[j].i_syn01.w <= (1 << 22) + (i << 10) + (j << 12);
        end
    end
end
for (i=0; i<`HIDDEN1_SIZE; i=i+1) begin
    for (j=0; j<`HIDDEN2_SIZE; j=j+1) begin
        initial begin
            dut.g_syn12_o[i].g_syn12_i[j].i_syn12.w <= (1 << 22) + (i << 10) + (j << 12);
        end
    end
end
for (i=0; i<`HIDDEN2_SIZE; i=i+1) begin
    for (j=0; j<`OUTPUT_SIZE; j=j+1) begin
        initial begin
            dut.g_syn23_o[i].g_syn23_i[j].i_syn23.w <= (1 << 22) + (i << 10) + (j << 12);
        end
    end
end
for (i=0; i<`INPUT_SIZE; i=i+1) begin
    initial begin
        a0[i] <= (i % 4 == 0) << 24;
    end
end
for (i=0; i<`OUTPUT_SIZE; i=i+1) begin
    initial begin
        g3[i] <= (i == 4) << 24;
    end
end

endgenerate

initial begin
    clk <= 0;
    fp <= 0;
    bp <= 0;
    wu <= 0;
    w_layer <= 0;
    w_i <= 1;
    w_j <= 2;
    $monitor("time %4t fp %1b fp_out %1b a3[4] %24b bp %1b bp_out %1b w1[1][2] %24b", $time, fp, fp_out, a_test[23:0], bp, bp_out, w_out[23:0]);
    #5 clk<=1; #5 clk<=0;
    fp <= 1;
    #5 clk<=1; #5 clk<=0;
    fp <= 0;
    #5 clk<=1; #5 clk<=0;
    #5 clk<=1; #5 clk<=0;
    #5 clk<=1; #5 clk<=0;
    #5 clk<=1; #5 clk<=0;
    #5 clk<=1; #5 clk<=0;
    #5 clk<=1; #5 clk<=0;
    bp <= 1;
    #5 clk<=1; #5 clk<=0;
    bp <= 0;
    #5 clk<=1; #5 clk<=0;
    #5 clk<=1; #5 clk<=0;
    #5 clk<=1; #5 clk<=0;
    #5 clk<=1; #5 clk<=0;
    #5 clk<=1; #5 clk<=0;
    #5 clk<=1; #5 clk<=0;
    wu <= 1;
    w_in <= 24'b111100001100110010101010;
    #5 clk<=1; #5 clk<=0;
    wu <= 0;
    #5 clk<=1; #5 clk<=0;
    $finish;
end

endmodule

