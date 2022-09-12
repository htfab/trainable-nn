// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2022 Tamas Hubai

`default_nettype none

// basic arithmetics with saturation


// addition
// res = a + b

module add_sat_comb (
    input [`NUM_WIDTH-1:0] a,
    input [`NUM_WIDTH-1:0] b,
    output [`NUM_WIDTH-1:0] res
);

wire sig_a = a[`NUM_WIDTH-1];
wire sig_b = b[`NUM_WIDTH-1];
wire sig_sum;
wire [`NUM_WIDTH-1:0] sum;
assign {sig_sum, sum} = {sig_a, a} + {sig_b, b};
wire saturated = sig_sum != sum[`NUM_WIDTH-1];
assign res = saturated ? {sig_sum, {(`NUM_WIDTH-1){~sig_sum}}} : sum;

endmodule


// subtraction
// res = a - b

module sub_sat_comb (
    input [`NUM_WIDTH-1:0] a,
    input [`NUM_WIDTH-1:0] b,
    output [`NUM_WIDTH-1:0] res
);

wire sig_a = a[`NUM_WIDTH-1];
wire sig_b = b[`NUM_WIDTH-1];
wire sig_sum;
wire [`NUM_WIDTH-1:0] sum;
assign {sig_sum, sum} = {sig_a, a} - {sig_b, b};
wire saturated = sig_sum != sum[`NUM_WIDTH-1];
assign res = saturated ? {sig_sum, {(`NUM_WIDTH-1){~sig_sum}}} : sum;

endmodule


// multiplication
// res = a * b

module mul_sat_comb (
    input [`NUM_WIDTH-1:0] a,
    input [`NUM_WIDTH-1:0] b,
    output [`NUM_WIDTH-1:0] res
);

wire sig_a = a[`NUM_WIDTH-1];
wire sig_b = b[`NUM_WIDTH-1];
wire sat_a = |a[`NUM_WIDTH-1:`MUL_INT_WIDTH+`FRAC_WIDTH-1] & ~&a[`NUM_WIDTH-1:`MUL_INT_WIDTH+`FRAC_WIDTH-1];
wire sat_b = |b[`NUM_WIDTH-1:`MUL_INT_WIDTH+`FRAC_WIDTH-1] & ~&b[`NUM_WIDTH-1:`MUL_INT_WIDTH+`FRAC_WIDTH-1];
wire [`MUL_INT_WIDTH+`PRE_MUL_FRAC_WIDTH-1:0] short_a = sat_a ? {sig_a, {(`MUL_INT_WIDTH+`PRE_MUL_FRAC_WIDTH-1){~sig_a}}} : a[`MUL_INT_WIDTH+`FRAC_WIDTH-1:`FRAC_WIDTH-`PRE_MUL_FRAC_WIDTH];
wire [`MUL_INT_WIDTH+`PRE_MUL_FRAC_WIDTH-1:0] short_b = sat_b ? {sig_b, {(`MUL_INT_WIDTH+`PRE_MUL_FRAC_WIDTH-1){~sig_b}}} : b[`MUL_INT_WIDTH+`FRAC_WIDTH-1:`FRAC_WIDTH-`PRE_MUL_FRAC_WIDTH];
wire sig_mul;
wire [`MUL_INT_WIDTH-1:0] mul_hi;
wire [`MUL_INT_WIDTH+`POST_MUL_FRAC_WIDTH-2:0] mul_md;
wire [2*`PRE_MUL_FRAC_WIDTH-`POST_MUL_FRAC_WIDTH-1:0] mul_lo;
assign {sig_mul, mul_hi, mul_md, mul_lo} = {{(`MUL_INT_WIDTH+`PRE_MUL_FRAC_WIDTH){sig_a}}, short_a} * {{(`MUL_INT_WIDTH+`PRE_MUL_FRAC_WIDTH){sig_b}}, short_b};
wire saturated = |{sig_mul, mul_hi} & ~&{sig_mul, mul_hi};
assign res = saturated ? {sig_mul, {(`NUM_WIDTH-1){~sig_mul}}} : {{(`INT_WIDTH-`MUL_INT_WIDTH+1){sig_mul}}, mul_md, {(`FRAC_WIDTH-`POST_MUL_FRAC_WIDTH){1'b0}}};

endmodule


// maximum & argmax
// res_val = max(x)
// res_pos = argmax(x)

module max_comb (
    input [`OUTPUT_SIZE*`NUM_WIDTH-1:0] x_pk,
    output [`NUM_WIDTH-1:0] res_val,
    output [`INDEX_WIDTH-1:0] res_pos
);

wire [`NUM_WIDTH-1:0] x[`OUTPUT_SIZE-1:0];
`UNPACK_ARRAY(`NUM_WIDTH, `OUTPUT_SIZE, x, x_pk)

generate genvar g; genvar h;

for (g=0; g<`OUTPUT_SIZE; g=g+1) begin:g_max_o
    wire [`OUTPUT_SIZE-1:0] is_greater;
    for (h=0; h<`OUTPUT_SIZE; h=h+1) begin:g_max_i
        assign is_greater[h] = $signed(x[g]) >= $signed(x[h]);
    end
    wire is_max = &is_greater;
    wire [`NUM_WIDTH-1:0] cur_val = is_max ? x[g] : {(`NUM_WIDTH){1'b0}};
    wire [`NUM_WIDTH-1:0] max_val;
    wire [`INDEX_WIDTH-1:0] pos;
    if (g==0) begin
        assign max_val = cur_val;
        assign pos = 0;
    end else begin
        assign max_val = g_max_o[g-1].max_val | cur_val;
        assign pos = is_max ? g : g_max_o[g-1].pos;
    end
end
assign res_val = g_max_o[`OUTPUT_SIZE-1].max_val;
assign res_pos = g_max_o[`OUTPUT_SIZE-1].pos;

endgenerate

endmodule

