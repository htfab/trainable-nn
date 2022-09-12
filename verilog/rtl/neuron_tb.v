// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2022 Tamas Hubai

`default_nettype none

// testbenches for neuron.v


// synapse is an edge between two neurons with two-way propagation
// and an updatable weight

module synapse_tb ();

reg clk;
reg fp;
wire fp_out;
reg [`NUM_WIDTH-1:0] a;
wire [`NUM_WIDTH-1:0] zc;
reg bp;
wire bp_out;
reg [`NUM_WIDTH-1:0] e;
wire [`NUM_WIDTH-1:0] tc;
reg wu;
reg [`NUM_WIDTH-1:0] w_in;
wire [`NUM_WIDTH-1:0] w_out;

synapse dut (
    .clk,
    .fp,
    .fp_out,
    .a,
    .zc,
    .bp,
    .bp_out,
    .e,
    .tc,
    .wu,
    .w_in,
    .w_out
);

initial begin
    clk <= 0;
    fp <= 0;
    bp <= 0;
    wu <= 0;
    $monitor("time %4t fp %1b fp_out %1b a %16b zc %16b bp %1b bp_out %1b e %16b tc %16b wu %1b w_in %16b w_out %16b", $time, fp, fp_out, a[31:16], zc[31:16], bp, bp_out, e[31:16], tc[31:16], wu, w_in[31:16], w_out[31:16]);
    #5 clk<=1; #5 clk<=0;
    wu <= 1;
    w_in <= 3 << `FRAC_WIDTH;
    #5 clk<=1; #5 clk<=0;
    wu <= 0;
    w_in <= 5 << `FRAC_WIDTH;
    #5 clk<=1; #5 clk<=0;
    a <= 7 << `FRAC_WIDTH;
    #5 clk<=1; #5 clk<=0;
    fp <= 1;
    #5 clk<=1; #5 clk<=0;
    fp <= 0;
    a <= 5 << `FRAC_WIDTH;
    #5 clk<=1; #5 clk<=0;
    e <= 7 << `FRAC_WIDTH;
    #5 clk<=1; #5 clk<=0;
    bp <= 1;
    #5 clk<=1; #5 clk<=0;
    #5 clk<=1; #5 clk<=0;
    #5 clk<=1; #5 clk<=0;
    bp <= 0;
    #5 clk<=1; #5 clk<=0;
    $finish;
end

endmodule


// generic neuron with two-way propagation that needs to be connected to
// the respective activation function and its derivative to make
// either a ReLU or a softmax neuron

module neuron_tb ();

reg clk;
reg fp;
wire fp_out;
reg [`NUM_WIDTH-1:0] z;
wire [`NUM_WIDTH-1:0] a;
reg bp;
wire bp_out;
reg [`NUM_WIDTH-1:0] t;
wire [`NUM_WIDTH-1:0] e;
wire [`NUM_WIDTH-1:0] to_act;
wire [`NUM_WIDTH-1:0] from_act;
wire [`NUM_WIDTH-1:0] from_act_diff;

neuron dut (
    .clk,
    .fp,
    .fp_out,
    .z,
    .a,
    .bp,
    .bp_out,
    .t,
    .e,
    .to_act,
    .from_act,
    .from_act_diff
);

assign from_act = to_act * 9;
assign from_act_diff = to_act * 17;

initial begin
    clk <= 0;
    fp <= 0;
    bp <= 0;
    $monitor("time %4t fp %1b fp_out %1b z %16b a %16b bp %1b bp_out %1b t %16b e %16b ta %16b fa %16b fad %16b", $time, fp, fp_out, z[35:20], a[35:20], bp, bp_out, t[35:20], e[35:20], to_act[35:20], from_act[35:20], from_act_diff[35:20]);
    #5 clk<=1; #5 clk<=0;
    z <= 3 << `FRAC_WIDTH;
    #5 clk<=1; #5 clk<=0;
    fp <= 1;
    #5 clk<=1; #5 clk<=0;
    fp <= 0;
    z <= 5 << `FRAC_WIDTH;
    #5 clk<=1; #5 clk<=0;
    t <= 7 << `FRAC_WIDTH;
    #5 clk<=1; #5 clk<=0;
    bp <= 1;
    #5 clk<=1; #5 clk<=0;
    bp <= 0;
    t <= 9 << `FRAC_WIDTH;
    #5 clk<=1; #5 clk<=0;
    $finish;
end

endmodule

