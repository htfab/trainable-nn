// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2022 Tamas Hubai

`default_nettype none

// synapse and neuron primitives for building up the neural network layers


// synapse is an edge between two neurons with two-way propagation
// and an updatable weight

module synapse (
    input clk,
    input fp, // forward propagation
    output reg fp_out,
    input [`NUM_WIDTH-1:0] a,
    output reg [`NUM_WIDTH-1:0] zc,
    input bp, // backward propagation
    output reg bp_out,
    input [`NUM_WIDTH-1:0] e,
    output reg [`NUM_WIDTH-1:0] tc,
    input wu, // weight update
    input [`NUM_WIDTH-1:0] w_in,
    output [`NUM_WIDTH-1:0] w_out
);

reg [`NUM_WIDTH-1:0] w;
assign w_out = w;

wire [`NUM_WIDTH-1:0] zn;
mul_sat_comb i_mul_z (
    .a(a),
    .b(w),
    .res(zn)
);

wire [`NUM_WIDTH-1:0] tn;
mul_sat_comb i_mul_t (
    .a(e),
    .b(w),
    .res(tn)
);

wire [`NUM_WIDTH-1:0] cn;
mul_sat_comb i_mul_c (
    .a(a),
    .b(e),
    .res(cn)
);

wire [`NUM_WIDTH-1:0] wn;
sub_sat_comb i_sub_w (
    .a(w),
    .b($signed(cn) >>> `LEARN_SHIFT),
    .res(wn)
);

always @(posedge clk) begin
    if (fp) begin
        zc <= zn;
    end
    fp_out <= fp;
    if (bp) begin
        tc <= tn;
        w <= wn; 
    end
    bp_out <= bp;
    if (wu) begin
        w <= w_in;
    end
end

endmodule


// generic neuron with two-way propagation that needs to be connected to
// the respective activation function and its derivative to make
// either a ReLU or a softmax neuron

module neuron (
    input clk,
    input fp, // forward propagation
    output reg fp_out,
    input [`NUM_WIDTH-1:0] z,
    output reg [`NUM_WIDTH-1:0] a,
    input bp, // backward propagation
    output reg bp_out,
    input [`NUM_WIDTH-1:0] t,
    output reg [`NUM_WIDTH-1:0] e,
    output [`NUM_WIDTH-1:0] to_act, // to activation function
    input [`NUM_WIDTH-1:0] from_act,
    input [`NUM_WIDTH-1:0] from_act_diff
);

assign to_act = z;

wire [`NUM_WIDTH-1:0] en;
mul_sat_comb i_mul_e (
    .a(t),
    .b(from_act_diff),
    .res(en)
);

always @(posedge clk) begin
    if (fp) begin
        a <= from_act;
    end
    fp_out <= fp;
    if (bp) begin
        e <= en;
    end
    bp_out <= bp;
end

endmodule

