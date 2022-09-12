// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2022 Tamas Hubai

`default_nettype none

// wrapper for neural_network that allows
// - setting initial weights, inputs & ground truth
// - retrieving outputs
// - starting forward or backward propagation
// - detecting when forward or backward propagation finishes
// by using memory i/o within a single virtual address space

module neural_interface (
    input clk,
    input [23:0] addr,
    input [`NUM_WIDTH-1:0] data_in,
    input we,
    output reg [`NUM_WIDTH-1:0] data_out
);

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

neural_network i_nn (
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

wire [`NUM_WIDTH-1:0] _ignore_a3;
wire [`INDEX_WIDTH-1:0] argmax_a3;
max_comb i_max_a3 (
    .x_pk(a3_pk),
    .res_val(_ignore_a3),
    .res_pos(argmax_a3)
);

wire [`NUM_WIDTH-1:0] _ignore_g3;
wire [`INDEX_WIDTH-1:0] argmax_g3;
max_comb i_max_g3 (
    .x_pk(g3_pk),
    .res_val(_ignore_g3),
    .res_pos(argmax_g3)
);

reg fp_out_hold;
reg bp_out_hold;
wire fp_out_hn = fp_out_hold | fp_out;
wire bp_out_hn = bp_out_hold | bp_out;

wire [3:0] sel = addr[23:20];
wire [9:0] index_h = addr[19:10];
wire [9:0] index_l = addr[9:0];

always @(posedge clk) begin
    fp <= 0;
    bp <= 0;
    wu <= 0;
    fp_out_hold <= fp_out_hn;
    bp_out_hold <= bp_out_hn;
    data_out <= {(`NUM_WIDTH){1'b0}};
    if (sel[3:2]==0) begin
        w_layer <= sel[1:0];
        w_i <= index_h;
        w_j <= index_l;
        data_out <= w_out;
        if (we) begin
            w_in <= data_in;
            wu <= 1;
        end
    end else if (sel==4) begin
        data_out <= a0[index_l];
        if (we) begin
            a0[index_l] <= data_in;
        end 
    end else if (sel==5) begin
        data_out <= a3[index_l];
    end else if (sel==6) begin
        data_out <= g3[index_l];
        if (we) begin
            g3[index_l] <= data_in;
        end
    end else if (sel==7) begin
        if (index_l == 0) begin
            data_out <= {(`NUM_WIDTH){fp_out_hn}};
            if (we) begin
                if (|data_in) begin
                    fp <= 1;
                end else begin
                    fp_out_hold <= 0;
                end
            end
        end else if (index_l == 1) begin
            data_out <= {(`NUM_WIDTH){bp_out_hn}};
            if (we) begin
                if (|data_in) begin
                    bp <= 1;
                end else begin
                    bp_out_hold <= 0;
                end
            end
        end else if (index_l == 2) begin
            data_out <= argmax_a3 << `FRAC_WIDTH;
        end else if (index_l == 3) begin
            data_out <= argmax_g3 << `FRAC_WIDTH;
        end
    end
end

endmodule

