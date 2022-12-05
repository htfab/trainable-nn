// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2022 Tamas Hubai

`default_nettype none

// testbenches for math.v


// addition

module add_sat_comb_tb ();

reg [`NUM_WIDTH-1:0] a;
reg [`NUM_WIDTH-1:0] b;
wire [`NUM_WIDTH-1:0] res;

add_sat_comb dut (
    .a,
    .b,
    .res
);

initial begin
    $monitor("time %4t a %64b b %64b res %64b", $time, a, b, res);
    a <= 1;
    b <= 2;
    #10
    a <= -1;
    b <= -2;
    #10
    a[`NUM_WIDTH-1] <= 0;
    b[`NUM_WIDTH-1] <= 0;
    #10
    b = 2;
    b[`NUM_WIDTH-1] <= 1;
    #10
    a = 1;
    a[`NUM_WIDTH-1] <= 1;
    $finish;
end

endmodule


// subtraction

module sub_sat_comb_tb ();

reg [`NUM_WIDTH-1:0] a;
reg [`NUM_WIDTH-1:0] b;
wire [`NUM_WIDTH-1:0] res;

sub_sat_comb dut (
    .a,
    .b,
    .res
);

initial begin
    $monitor("time %4t a %64b b %64b res %64b", $time, a, b, res);
    a <= 1;
    b <= 2;
    #10
    a <= -1;
    b <= -2;
    #10
    a[`NUM_WIDTH-1] <= 0;
    b[`NUM_WIDTH-1] <= 0;
    #10
    b = 2;
    b[`NUM_WIDTH-1] <= 1;
    #10
    a = 1;
    a[`NUM_WIDTH-1] <= 1;
    $finish;
end

endmodule


// multiplication

module mul_sat_comb_tb ();

reg [`NUM_WIDTH-1:0] a;
reg [`NUM_WIDTH-1:0] b;
wire [`NUM_WIDTH-1:0] res;

mul_sat_comb dut (
    .a,
    .b,
    .res
);

initial begin
    $monitor("time %4t a %64b b %64b res %64b", $time, a, b, res);
    a <= 1 << `FRAC_WIDTH;
    b <= 2 << `FRAC_WIDTH;
    #10
    a <= -1 << `FRAC_WIDTH;
    b <= -2 << `FRAC_WIDTH;
    #10
    a[`NUM_WIDTH-1] <= 0;
    b[`NUM_WIDTH-1] <= 0;
    #10
    b <= 2 << `FRAC_WIDTH;
    b[`NUM_WIDTH-1] <= 1;
    #10
    a <= 1 << `FRAC_WIDTH;
    a[`NUM_WIDTH-1] <= 1;
    $finish;
end

endmodule


// maximum & argmax

module max_comb_tb ();

reg [`NUM_WIDTH-1:0] x[`OUTPUT_SIZE-1:0];
wire [`NUM_WIDTH-1:0] res_val;
wire [`INDEX_WIDTH-1:0] res_pos;

wire [`OUTPUT_SIZE*`NUM_WIDTH-1:0] x_pk;
`PACK_ARRAY(`NUM_WIDTH, `OUTPUT_SIZE, x, x_pk)

max_comb dut (
    .x_pk,
    .res_val,
    .res_pos
);

reg [`INDEX_WIDTH-1:0] i;

initial begin
    $monitor("time %4t x[0] %32b x[1] %32b x[2] %32b res_val %32b res_pos %10b", $time, x[0][31:0], x[1][31:0], x[2][31:0], res_val[31:0], res_pos);
    for(i=0; i<`OUTPUT_SIZE; i=i+1) begin
        x[i] <= -20;
    end
    x[0] <= 0;
    x[1] <= 0;
    x[2] <= 0;
    #10
    x[0] <= 1;
    x[1] <= 2;
    x[2] <= 3;
    #10
    x[0] <= 10;
    #10
    x[1] <= 10;
    #10
    x[2] <= 20;
    #10
    x[1] <= 20;
    #10
    x[0] <= 20;
    #10
    x[0] <= -1;
    x[1] <= -2;
    x[2] <= -3;
    #10
    x[0] <= 1;
    $finish;
end

endmodule

