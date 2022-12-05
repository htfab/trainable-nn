// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2022 Tamas Hubai

`default_nettype none

// testbenches for actfn.v


// leaky ReLU

module leaky_relu_comb_tb ();

reg [`NUM_WIDTH-1:0] x;
wire [`NUM_WIDTH-1:0] res;

leaky_relu_comb dut (
    .x,
    .res
);

initial begin
    $monitor("time %4t x %64b res %64b", $time, x, res);
    x <= 3;
    #10
    x <= -3;
    #10
    x <= -3 << `LEAK_SHIFT;
    $finish;
end

endmodule


// derivative of leaky ReLU

module leaky_relu_diff_comb_tb ();

reg [`NUM_WIDTH-1:0] x;
wire [`NUM_WIDTH-1:0] res;

leaky_relu_diff_comb dut (
    .x,
    .res
);

initial begin
    $monitor("time %4t x %64b res %64b", $time, x, res);
    x <= 3;
    #10
    x <= -3;
    #10
    x <= -3 << `LEAK_SHIFT;
    $finish;
end

endmodule


// very rough approximation of 2^x, used in softmax

module approx_exp_comb_tb ();

reg [`NUM_WIDTH-1:0] x;
wire [`NUM_WIDTH-1:0] res;

approx_exp_comb dut (
    .x,
    .res
);

initial begin
    $monitor("time %4t x %64b res %64b", $time, x, res);
    x <= 3;
    #10
    x <= 3 << `FRAC_WIDTH;
    #10
    x <= -3 << `FRAC_WIDTH;
    #10
    x <= (`INT_WIDTH-2) << `FRAC_WIDTH;
    #10
    x <= (`INT_WIDTH-1) << `FRAC_WIDTH;
    #10
    x <= (-`FRAC_WIDTH) << `FRAC_WIDTH;
    #10
    x <= (-`FRAC_WIDTH-1) << `FRAC_WIDTH;
    $finish;
end

endmodule


// piecewise linear approximation of 1/x, used in softmax

module approx_inv_comb_tb ();

reg [`NUM_WIDTH-1:0] x;
wire [`NUM_WIDTH-1:0] res;

approx_inv_comb dut (
    .x,
    .res
);

initial begin
    $monitor("time %4t x %64b res %64b m 1%24b minv %25b", $time, x, res, dut.m, dut.minv);
    x <= 1;
    #10
    x <= 1 << `FRAC_WIDTH;
    #10
    x <= 1 << (`FRAC_WIDTH + 2);
    #10
    x <= 1 << (`FRAC_WIDTH - 3);
    #10
    x <= 4'b1000 << `FRAC_WIDTH;
    #10
    x <= 4'b1001 << `FRAC_WIDTH;
    #10
    x <= 4'b1010 << `FRAC_WIDTH;
    #10
    x <= 4'b1011 << `FRAC_WIDTH;
    #10
    x <= 4'b1100 << `FRAC_WIDTH;
    #10
    x <= 4'b1101 << `FRAC_WIDTH;
    #10
    x <= 4'b1110 << `FRAC_WIDTH;
    #10
    x <= 4'b1111 << `FRAC_WIDTH;
    #10
    $finish;
end

endmodule


// softmax using approximated 2^x and 1/x

module approx_softmax_comb_tb ();

reg [`NUM_WIDTH-1:0] x[`OUTPUT_SIZE-1:0];
wire [`NUM_WIDTH-1:0] res[`OUTPUT_SIZE-1:0];

wire [`OUTPUT_SIZE*`NUM_WIDTH-1:0] x_pk;
`PACK_ARRAY(`NUM_WIDTH, `OUTPUT_SIZE, x, x_pk)

wire [`OUTPUT_SIZE*`NUM_WIDTH-1:0] res_pk;
`UNPACK_ARRAY(`NUM_WIDTH, `OUTPUT_SIZE, res, res_pk)

approx_softmax_comb dut (
    .x_pk,
    .res_pk
);

wire [`NUM_WIDTH-1:0] res0 = res[0];    // workaround for segfault in vvp
wire [`NUM_WIDTH-1:0] res1 = res[1];
wire [`NUM_WIDTH-1:0] res2 = res[2];

reg [`INDEX_WIDTH-1:0] i;
wire [31:0] hint = 32'b1 << `FRAC_WIDTH;

initial begin
    $display("TIME vvvv X[0] %32b X[1] %32b X[2] %32b RES[0] %32b RES[1] %32b RES[2] %32b", hint, hint, hint, hint, hint, hint);
    $monitor("time %4t x[0] %32b x[1] %32b x[2] %32b res[0] %32b res[1] %32b res[2] %32b", $time, x[0][31:0], x[1][31:0], x[2][31:0], res0[31:0], res1[31:0], res2[31:0]);
    for(i=0; i<`OUTPUT_SIZE; i=i+1) begin
        x[i] <= 0;
    end
    x[0] <= 0;
    x[1] <= 0;
    x[2] <= 0;
    #10
    x[0] <= 1 << (`FRAC_WIDTH-4);
    x[1] <= 2 << (`FRAC_WIDTH-4);
    x[2] <= 3 << (`FRAC_WIDTH-4);
    #10
    x[0] <= 1 << `FRAC_WIDTH;
    #10
    x[1] <= 1 << `FRAC_WIDTH;
    #10
    x[2] <= 2 << `FRAC_WIDTH;
    #10
    x[1] <= 2 << `FRAC_WIDTH;
    #10
    x[0] <= 2 << `FRAC_WIDTH;
    #10
    x[0] <= 1 << (`FRAC_WIDTH+4);
    #10
    x[1] <= 2 << (`FRAC_WIDTH+4);
    #10
    x[2] <= 3 << (`FRAC_WIDTH+4);
    $finish;
end

endmodule


// derivative of softmax

module approx_softmax_diff_comb_tb ();

reg [`NUM_WIDTH-1:0] x[`OUTPUT_SIZE-1:0];
wire [`NUM_WIDTH-1:0] res[`OUTPUT_SIZE-1:0];

wire [`OUTPUT_SIZE*`NUM_WIDTH-1:0] x_pk;
`PACK_ARRAY(`NUM_WIDTH, `OUTPUT_SIZE, x, x_pk)
wire [`OUTPUT_SIZE*`NUM_WIDTH-1:0] res_pk;
`UNPACK_ARRAY(`NUM_WIDTH, `OUTPUT_SIZE, res, res_pk)

approx_softmax_diff_comb dut (
    .x_pk,
    .res_pk
);

wire [`NUM_WIDTH-1:0] res0 = res[0];    // workaround for segfault in vvp
wire [`NUM_WIDTH-1:0] res1 = res[1];
wire [`NUM_WIDTH-1:0] res2 = res[2];

reg [`INDEX_WIDTH-1:0] i;
wire [31:0] hint = 32'b1 << `FRAC_WIDTH;

initial begin
    $display("TIME vvvv X[0] %32b X[1] %32b X[2] %32b RES[0] %32b RES[1] %32b RES[2] %32b", hint, hint, hint, hint, hint, hint);
    $monitor("time %4t x[0] %32b x[1] %32b x[2] %32b res[0] %32b res[1] %32b res[2] %32b", $time, x[0][31:0], x[1][31:0], x[2][31:0], res0[31:0], res1[31:0], res2[31:0]);
    for(i=0; i<`OUTPUT_SIZE; i=i+1) begin
        x[i] <= 0;
    end
    x[0] <= 0;
    x[1] <= 0;
    x[2] <= 0;
    #10
    x[0] <= 1 << (`FRAC_WIDTH-4);
    x[1] <= 2 << (`FRAC_WIDTH-4);
    x[2] <= 3 << (`FRAC_WIDTH-4);
    #10
    x[0] <= 1 << `FRAC_WIDTH;
    #10
    x[1] <= 1 << `FRAC_WIDTH;
    #10
    x[2] <= 2 << `FRAC_WIDTH;
    #10
    x[1] <= 2 << `FRAC_WIDTH;
    #10
    x[0] <= 2 << `FRAC_WIDTH;
    #10
    x[0] <= 1 << (`FRAC_WIDTH+4);
    #10
    x[1] <= 2 << (`FRAC_WIDTH+4);
    #10
    x[2] <= 3 << (`FRAC_WIDTH+4);
    $finish;
end

endmodule

