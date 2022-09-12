// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2022 Tamas Hubai

`default_nettype none

// activation functions used in the neural network


// leaky ReLU

module leaky_relu_comb (
    input [`NUM_WIDTH-1:0] x,
    output [`NUM_WIDTH-1:0] res
);

wire sig_x = x[`NUM_WIDTH-1];
assign res = sig_x ? {{(`LEAK_SHIFT){1'b1}}, x[`NUM_WIDTH-1:`LEAK_SHIFT]} : x;

endmodule


// derivative of leaky ReLU

module leaky_relu_diff_comb (
    input [`NUM_WIDTH-1:0] x,
    output [`NUM_WIDTH-1:0] res
);

wire sig_x = x[`NUM_WIDTH-1];

assign res = sig_x ?
    {{(`INT_WIDTH+`LEAK_SHIFT-1){1'b0}}, 1'b1, {(`FRAC_WIDTH-`LEAK_SHIFT){1'b0}}} :
    {{(`INT_WIDTH-1){1'b0}}, 1'b1, {(`FRAC_WIDTH){1'b0}}};

endmodule


// very rough approximation of 2^x, used in softmax

module approx_exp_comb (
    input [`NUM_WIDTH-1:0] x,
    output [`NUM_WIDTH-1:0] res
);

wire saturated = ~x[`NUM_WIDTH-1] & (x[`NUM_WIDTH-1:`FRAC_WIDTH] > `INT_WIDTH - 2);

assign res[`NUM_WIDTH-1] = 1'b0;
generate genvar g;
for (g=0; g<`NUM_WIDTH-1; g=g+1) begin:g_exp
    assign res[g] = saturated | (x[`NUM_WIDTH-1:`FRAC_WIDTH] == g - `FRAC_WIDTH);
end
endgenerate

endmodule


// piecewise linear approximation of 1/x, used in softmax

module approx_inv_comb (
    input [`NUM_WIDTH-1:0] x,   // assuming x > 0
    output [`NUM_WIDTH-1:0] res
);

wire [`NUM_WIDTH:0] bnd;
wire [`NUM_WIDTH-1:0] msb;
wire [`FRAC_WIDTH-1:0] m;

assign bnd[`NUM_WIDTH] = 0;

generate genvar g;

for (g=`NUM_WIDTH-1; g>=0; g=g-1) begin:g_msb
    assign bnd[g] = bnd[g+1] | x[g];
    assign msb[g] = bnd[g] & ~bnd[g+1];
end
for (g=0; g<`NUM_WIDTH; g=g+1) begin:g_mant
    wire [`FRAC_WIDTH-1:0] mc = msb[g] ? ({x, {(`FRAC_WIDTH){1'b0}}} >> g) : {(`FRAC_WIDTH){1'b0}};
    wire [`FRAC_WIDTH-1:0] ms;
    if (g==0) begin:i_mantz
        assign ms = mc;
    end else begin:i_mantnz
        assign ms = g_mant[g-1].ms | mc;
    end
end
assign m = g_mant[`NUM_WIDTH-1].ms;

// m contains the input bit-shifted to within [1, 2), with its integer part (i.e. 1) removed
// for 1 <= x < 1.25 we use 1/x ~= 115/64 - 51/64 x
wire [`FRAC_WIDTH:0] minv_a = {7'd115, {(`FRAC_WIDTH-6){1'b0}}} - (({{(`FRAC_WIDTH){1'b0}}, 7'd51} * {7'd1, m}) >> 6);
// for 1.25 <= x < 1.5 we use 1/x ~= 95/64 - 35/64 x
wire [`FRAC_WIDTH:0] minv_b = {7'd95, {(`FRAC_WIDTH-6){1'b0}}} - (({{(`FRAC_WIDTH){1'b0}}, 7'd35} * {7'd1, m}) >> 6);
// for 1.5 <= x < 1.75 we use 1/x ~= 157/128 - 3/8 x
wire [`FRAC_WIDTH:0] minv_c = {8'd157, {(`FRAC_WIDTH-7){1'b0}}} - (({{(`FRAC_WIDTH){1'b0}}, 3'd3} * {3'd1, m}) >> 3);
// for 1.75 <= x < 2 we use 1/x ~= 17/16 - 9/32 x
wire [`FRAC_WIDTH:0] minv_d = {5'd17, {(`FRAC_WIDTH-4){1'b0}}} - (({{(`FRAC_WIDTH){1'b0}}, 5'd9} * {5'd1, m}) >> 5);
wire [`FRAC_WIDTH:0] minv = m[`FRAC_WIDTH-1] ? (m[`FRAC_WIDTH-2] ? minv_d : minv_c) : (m[`FRAC_WIDTH-2] ? minv_b : minv_a);

for (g=0; g<`NUM_WIDTH; g=g+1) begin:g_mrec
    wire [`NUM_WIDTH-1:0] mrc = msb[g] ? ({{(`INT_WIDTH){1'b0}}, minv, {(`FRAC_WIDTH){1'b0}}} >> g) : {(`NUM_WIDTH){1'b0}};    
    wire [`NUM_WIDTH-1:0] mrs;
    if (g==0) begin:i_mrecz
        assign mrs = mrc;
    end else begin:i_mrecnz
        assign mrs = g_mrec[g-1].mrs | mrc;
    end
end
assign res = g_mrec[`NUM_WIDTH-1].mrs;

endgenerate

endmodule


// softmax using approximated 2^x and 1/x

module approx_softmax_comb (
    input [`OUTPUT_SIZE*`NUM_WIDTH-1:0] x_pk,
    output [`OUTPUT_SIZE*`NUM_WIDTH-1:0] res_pk
);

wire [`NUM_WIDTH-1:0] x[`OUTPUT_SIZE-1:0];
wire [`NUM_WIDTH-1:0] res[`OUTPUT_SIZE-1:0];

`UNPACK_ARRAY(`NUM_WIDTH, `OUTPUT_SIZE, x, x_pk)
`PACK_ARRAY(`NUM_WIDTH, `OUTPUT_SIZE, res, res_pk)

wire [`NUM_WIDTH-1:0] xmax;
wire [`INDEX_WIDTH-1:0] _ignore;

max_comb i_max (
    .x_pk,
    .res_val(xmax),
    .res_pos(_ignore)
);

wire [`NUM_WIDTH-1:0] dexp[`OUTPUT_SIZE-1:0];
wire [`NUM_WIDTH-1:0] esum;

generate genvar g;

for (g=0; g<`OUTPUT_SIZE; g=g+1) begin:g_expsum
    wire [`NUM_WIDTH-1:0] diff;
    sub_sat_comb i_sub (
        .a(x[g]),
        .b(xmax),
        .res(diff)
    );
    approx_exp_comb i_exp (
        .x(diff),
        .res(dexp[g])
    );
    wire [`NUM_WIDTH-1:0] psum;
    if (g==0) begin
        assign psum = dexp[g];
    end else begin
        assign psum = g_expsum[g-1].psum + dexp[g];
    end
end
assign esum = g_expsum[`OUTPUT_SIZE-1].psum;

endgenerate

wire [`NUM_WIDTH-1:0] isum;
approx_inv_comb i_inv (
    .x(esum),
    .res(isum)
);

generate

for (g=0; g<`OUTPUT_SIZE; g=g+1) begin:g_div
    mul_sat_comb i_mul (
        .a(dexp[g]),
        .b(isum),
        .res(res[g])
    );
end

endgenerate

endmodule


// derivative of softmax

module approx_softmax_diff_comb (
    input [`OUTPUT_SIZE*`NUM_WIDTH-1:0] x_pk,
    output [`OUTPUT_SIZE*`NUM_WIDTH-1:0] res_pk
);

wire [`OUTPUT_SIZE*`NUM_WIDTH-1:0] sm_pk;

approx_softmax_comb i_sm (
    .x_pk,
    .res_pk(sm_pk)
);

wire [`NUM_WIDTH-1:0] sm[`OUTPUT_SIZE-1:0];
wire [`NUM_WIDTH-1:0] res[`OUTPUT_SIZE-1:0];

`UNPACK_ARRAY(`NUM_WIDTH, `OUTPUT_SIZE, sm, sm_pk)
`PACK_ARRAY(`NUM_WIDTH, `OUTPUT_SIZE, res, res_pk)

generate genvar g;

for (g=0; g<`OUTPUT_SIZE; g=g+1) begin
    wire [`NUM_WIDTH-1:0] sqr;
    mul_sat_comb i_mul (
        .a(sm[g]),
        .b(sm[g]),
        .res(sqr)
    );
    sub_sat_comb i_sub (
        .a(sm[g]),
        .b(sqr),
        .res(res[g])
    );
end

endgenerate

endmodule

