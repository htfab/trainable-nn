// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2022 Tamas Hubai

`default_nettype none

// neural network composed of an input layer,
// two fully connected hidden layers with a ReLU activation function
// and a fully connected output layer with a softmax activation function

module neural_network (
    input clk,
    input fp,
    output fp_out,
    input [`INPUT_SIZE*`NUM_WIDTH-1:0] a0_pk,
    output [`OUTPUT_SIZE*`NUM_WIDTH-1:0] a3_pk,
    input bp,
    output bp_out,
    input [`OUTPUT_SIZE*`NUM_WIDTH-1:0] g3_pk, // ground truth
    input wu,
    input [1:0] w_layer,
    input [`INDEX_WIDTH-1:0] w_i,
    input [`INDEX_WIDTH-1:0] w_j,
    input [`NUM_WIDTH-1:0] w_in,
    output [`NUM_WIDTH-1:0] w_out
);

wire [`NUM_WIDTH-1:0] a0[`INPUT_SIZE-1:0];
`UNPACK_ARRAY(`NUM_WIDTH, `INPUT_SIZE, a0, a0_pk)
wire [`NUM_WIDTH-1:0] a3[`OUTPUT_SIZE-1:0];
`PACK_ARRAY(`NUM_WIDTH, `OUTPUT_SIZE, a3, a3_pk)
wire [`NUM_WIDTH-1:0] g3[`OUTPUT_SIZE-1:0];
`UNPACK_ARRAY(`NUM_WIDTH, `OUTPUT_SIZE, g3, g3_pk)

generate genvar g; genvar h;

// synapses between input layer & hidden layer 1
wire bp_s01;
wire [`NUM_WIDTH-1:0] e1[`HIDDEN1_SIZE-1:0];
for (g=0; g<`INPUT_SIZE; g=g+1) begin:g_syn01_o
    for (h=0; h<`HIDDEN1_SIZE; h=h+1) begin:g_syn01_i
        wire fp_out;
        wire bp_out;
        wire [`NUM_WIDTH-1:0] zc;
        wire [`NUM_WIDTH-1:0] tc; // ignored for input layer
        wire wu_sel = (w_layer == 0) && (w_i == g) && (w_j == h);
        wire [`NUM_WIDTH-1:0] w_out_r;
        synapse i_syn01 (
            .clk,
            .fp,
            .fp_out,
            .a(a0[g]),
            .zc,
            .bp(bp_s01),
            .bp_out,
            .e(e1[h]),
            .tc,
            .wu(wu && wu_sel),
            .w_in(w_in),
            .w_out(w_out_r)
        );
        wire [`NUM_WIDTH-1:0] w_out_s = wu_sel ? w_out_r : {(`NUM_WIDTH){1'b0}};
        wire [`NUM_WIDTH-1:0] w_out_a;
        if (h==0) begin
            assign w_out_a = w_out_s;
        end else begin
            assign w_out_a = g_syn01_i[h-1].w_out_a | w_out_s;
        end
    end
    wire [`NUM_WIDTH-1:0] w_out_b;
    if (g==0) begin
        assign w_out_b = g_syn01_i[`HIDDEN1_SIZE-1].w_out_a;
    end else begin
        assign w_out_b = g_syn01_o[g-1].w_out_b | g_syn01_i[`HIDDEN1_SIZE-1].w_out_a;
    end
end
wire [`NUM_WIDTH-1:0] w_out_c01 = g_syn01_o[`INPUT_SIZE-1].w_out_b;

wire [`NUM_WIDTH-1:0] z1[`HIDDEN1_SIZE-1:0];
for (g=0; g<`HIDDEN1_SIZE; g=g+1) begin:g_z1_o
    for (h=0; h<`INPUT_SIZE; h=h+1) begin:g_z1_i
        wire [`NUM_WIDTH-1:0] zc = g_syn01_o[h].g_syn01_i[g].zc;
        wire [`NUM_WIDTH-1:0] z1s;
        if (h==0) begin
            assign z1s = zc;
        end else begin
            add_sat_comb i_add_z1 (
                .a(g_z1_i[h-1].z1s),
                .b(zc),
                .res(z1s)
            );
        end
    end
    assign z1[g] = g_z1_i[`INPUT_SIZE-1].z1s;
end

wire fp_h1 = g_syn01_o[0].g_syn01_i[0].fp_out;
assign bp_out = g_syn01_o[0].g_syn01_i[0].bp_out;

// hidden layer 1
wire bp_h1;
wire [`NUM_WIDTH-1:0] a1[`HIDDEN1_SIZE-1:0];
wire [`NUM_WIDTH-1:0] t1[`HIDDEN1_SIZE-1:0];
for (g=0; g<`HIDDEN1_SIZE; g=g+1) begin:g_layer1
    wire fp_out;
    wire bp_out;
    wire [`NUM_WIDTH-1:0] to_act;
    wire [`NUM_WIDTH-1:0] from_act;
    wire [`NUM_WIDTH-1:0] from_act_diff;
    neuron i_neu_1 (
        .clk,
        .fp(fp_h1),
        .fp_out,
        .z(z1[g]),
        .a(a1[g]),
        .bp(bp_h1),
        .bp_out,
        .t(t1[g]),
        .e(e1[g]),
        .to_act,
        .from_act,
        .from_act_diff
    );
    leaky_relu_comb i_act_1 (
        .x(to_act),
        .res(from_act)
    );
    leaky_relu_diff_comb i_act_diff_1 (
        .x(to_act),
        .res(from_act_diff)
    );
end

wire fp_s12 = g_layer1[0].fp_out;
assign bp_s01 = g_layer1[0].bp_out;

// synapses between hidden layers 1 & 2
wire bp_s12;
wire [`NUM_WIDTH-1:0] e2[`HIDDEN2_SIZE-1:0];
for (g=0; g<`HIDDEN1_SIZE; g=g+1) begin:g_syn12_o
    for (h=0; h<`HIDDEN2_SIZE; h=h+1) begin:g_syn12_i
        wire fp_out;
        wire bp_out;
        wire [`NUM_WIDTH-1:0] zc;
        wire [`NUM_WIDTH-1:0] tc;
        wire wu_sel = (w_layer == 1) && (w_i == g) && (w_j == h);
        wire [`NUM_WIDTH-1:0] w_out_r;
        synapse i_syn12 (
            .clk,
            .fp(fp_s12),
            .fp_out,
            .a(a1[g]),
            .zc,
            .bp(bp_s12),
            .bp_out,
            .e(e2[h]),
            .tc,
            .wu(wu && wu_sel),
            .w_in(w_in),
            .w_out(w_out_r)
        );
        wire [`NUM_WIDTH-1:0] w_out_s = wu_sel ? w_out_r : {(`NUM_WIDTH){1'b0}};
        wire [`NUM_WIDTH-1:0] w_out_a;
        if (h==0) begin
            assign w_out_a = w_out_s;
        end else begin
            assign w_out_a = g_syn12_i[h-1].w_out_a | w_out_s;
        end
    end
    wire [`NUM_WIDTH-1:0] w_out_b;
    if (g==0) begin
        assign w_out_b = g_syn12_i[`HIDDEN2_SIZE-1].w_out_a;
    end else begin
        assign w_out_b = g_syn12_o[g-1].w_out_b | g_syn12_i[`HIDDEN2_SIZE-1].w_out_a;
    end
end
wire [`NUM_WIDTH-1:0] w_out_c12 = g_syn12_o[`HIDDEN1_SIZE-1].w_out_b;

wire [`NUM_WIDTH-1:0] z2[`HIDDEN2_SIZE-1:0];
for (g=0; g<`HIDDEN2_SIZE; g=g+1) begin:g_z2_o
    for (h=0; h<`HIDDEN1_SIZE; h=h+1) begin:g_z2_i
        wire [`NUM_WIDTH-1:0] zc = g_syn12_o[h].g_syn12_i[g].zc;
        wire [`NUM_WIDTH-1:0] z2s;
        if (h==0) begin
            assign z2s = zc;
        end else begin
            add_sat_comb i_add_z2 (
                .a(g_z2_i[h-1].z2s),
                .b(zc),
                .res(z2s)
            );
        end
    end
    assign z2[g] = g_z2_i[`HIDDEN1_SIZE-1].z2s;
end

for (g=0; g<`HIDDEN1_SIZE; g=g+1) begin:g_t1_o
    for(h=0; h<`HIDDEN2_SIZE; h=h+1) begin:g_t1_i
        wire [`NUM_WIDTH-1:0] tc = g_syn12_o[g].g_syn12_i[h].tc;
        wire [`NUM_WIDTH-1:0] t1s;
        if (h==0) begin
            assign t1s = tc;
        end else begin
            add_sat_comb i_add_t1 (
                .a(g_t1_i[h-1].t1s),
                .b(tc),
                .res(t1s)
            );
        end
    end
    assign t1[g] = g_t1_i[`HIDDEN2_SIZE-1].t1s;
end

wire fp_h2 = g_syn12_o[0].g_syn12_i[0].fp_out;
assign bp_h1 = g_syn12_o[0].g_syn12_i[0].bp_out;

// hidden layer 2
wire bp_h2;
wire [`NUM_WIDTH-1:0] a2[`HIDDEN2_SIZE-1:0];
wire [`NUM_WIDTH-1:0] t2[`HIDDEN2_SIZE-1:0];
for (g=0; g<`HIDDEN2_SIZE; g=g+1) begin:g_layer2
    wire fp_out;
    wire bp_out;
    wire [`NUM_WIDTH-1:0] to_act;
    wire [`NUM_WIDTH-1:0] from_act;
    wire [`NUM_WIDTH-1:0] from_act_diff;
    neuron i_neu_2 (
        .clk,
        .fp(fp_h2),
        .fp_out,
        .z(z2[g]),
        .a(a2[g]),
        .bp(bp_h2),
        .bp_out,
        .t(t2[g]),
        .e(e2[g]),
        .to_act,
        .from_act,
        .from_act_diff
    );
    leaky_relu_comb i_act_2 (
        .x(to_act),
        .res(from_act)
    );
    leaky_relu_diff_comb i_act_diff_2 (
        .x(to_act),
        .res(from_act_diff)
    );
end

wire fp_s23 = g_layer2[0].fp_out;
assign bp_s12 = g_layer2[0].bp_out;

// synapses between hidden layer 2 & output layer
wire bp_s23;
wire [`NUM_WIDTH-1:0] e3[`OUTPUT_SIZE-1:0];
for (g=0; g<`HIDDEN2_SIZE; g=g+1) begin:g_syn23_o
    for (h=0; h<`OUTPUT_SIZE; h=h+1) begin:g_syn23_i
        wire fp_out;
        wire bp_out;
        wire [`NUM_WIDTH-1:0] zc;
        wire [`NUM_WIDTH-1:0] tc;
        wire wu_sel = (w_layer == 2) && (w_i == g) && (w_j == h);
        wire [`NUM_WIDTH-1:0] w_out_r;
        synapse i_syn23 (
            .clk,
            .fp(fp_s23),
            .fp_out,
            .a(a2[g]),
            .zc,
            .bp(bp_s23),
            .bp_out,
            .e(e3[h]),
            .tc,
            .wu(wu && wu_sel),
            .w_in(w_in),
            .w_out(w_out_r)
        );
        wire [`NUM_WIDTH-1:0] w_out_s = wu_sel ? w_out_r : {(`NUM_WIDTH){1'b0}};
        wire [`NUM_WIDTH-1:0] w_out_a;
        if (h==0) begin
            assign w_out_a = w_out_s;
        end else begin
            assign w_out_a = g_syn23_i[h-1].w_out_a | w_out_s;
        end
    end
    wire [`NUM_WIDTH-1:0] w_out_b;
    if (g==0) begin
        assign w_out_b = g_syn23_i[`OUTPUT_SIZE-1].w_out_a;
    end else begin
        assign w_out_b = g_syn23_o[g-1].w_out_b | g_syn23_i[`OUTPUT_SIZE-1].w_out_a;
    end
end
wire [`NUM_WIDTH-1:0] w_out_c23 = g_syn23_o[`HIDDEN2_SIZE-1].w_out_b;

wire [`NUM_WIDTH-1:0] z3[`OUTPUT_SIZE-1:0];
for (g=0; g<`OUTPUT_SIZE; g=g+1) begin:g_z3_o
    for (h=0; h<`HIDDEN2_SIZE; h=h+1) begin:g_z3_i
        wire [`NUM_WIDTH-1:0] zc = g_syn23_o[h].g_syn23_i[g].zc;
        wire [`NUM_WIDTH-1:0] z3s;
        if (h==0) begin
            assign z3s = zc;
        end else begin
            add_sat_comb i_add_z3 (
                .a(g_z3_i[h-1].z3s),
                .b(zc),
                .res(z3s)
            );
        end
    end
    assign z3[g] = g_z3_i[`HIDDEN2_SIZE-1].z3s;
end

for (g=0; g<`HIDDEN2_SIZE; g=g+1) begin:g_t2_o
    for(h=0; h<`OUTPUT_SIZE; h=h+1) begin:g_t2_i
        wire [`NUM_WIDTH-1:0] tc = g_syn23_o[g].g_syn23_i[h].tc;
        wire [`NUM_WIDTH-1:0] t2s;
        if (h==0) begin
            assign t2s = tc;
        end else begin
            add_sat_comb i_add_t2 (
                .a(g_t2_i[h-1].t2s),
                .b(tc),
                .res(t2s)
            );
        end
    end
    assign t2[g] = g_t2_i[`OUTPUT_SIZE-1].t2s;
end

wire fp_h3 = g_syn23_o[0].g_syn23_i[0].fp_out;
assign bp_h2 = g_syn23_o[0].g_syn23_i[0].bp_out;

// output layer
wire [`NUM_WIDTH-1:0] t3[`OUTPUT_SIZE-1:0];
wire [`NUM_WIDTH-1:0] to_softmax[`OUTPUT_SIZE-1:0];
wire [`NUM_WIDTH-1:0] from_softmax[`OUTPUT_SIZE-1:0];
wire [`NUM_WIDTH-1:0] from_softmax_diff[`OUTPUT_SIZE-1:0];
for (g=0; g<`OUTPUT_SIZE; g=g+1) begin:g_layer3
    wire fp_out;
    wire bp_out;
    wire [`NUM_WIDTH-1:0] to_act;
    wire [`NUM_WIDTH-1:0] from_act;
    wire [`NUM_WIDTH-1:0] from_act_diff;
    neuron i_neu_3 (
        .clk,
        .fp(fp_h3),
        .fp_out,
        .z(z3[g]),
        .a(a3[g]),
        .bp,
        .bp_out,
        .t(t3[g]),
        .e(e3[g]),
        .to_act(to_softmax[g]),
        .from_act(from_softmax[g]),
        .from_act_diff(from_softmax_diff[g])
    );
    // feedback using ground truth
    sub_sat_comb i_sub_fb (
        .a(a3[g]),
        .b(g3[g]),
        .res(t3[g])
    );
end

wire [`OUTPUT_SIZE*`NUM_WIDTH-1:0] to_softmax_pk;
`PACK_ARRAY(`NUM_WIDTH, `OUTPUT_SIZE, to_softmax, to_softmax_pk)
wire [`OUTPUT_SIZE*`NUM_WIDTH-1:0] from_softmax_pk;
`UNPACK_ARRAY(`NUM_WIDTH, `OUTPUT_SIZE, from_softmax, from_softmax_pk)
wire [`OUTPUT_SIZE*`NUM_WIDTH-1:0] from_softmax_diff_pk;
`UNPACK_ARRAY(`NUM_WIDTH, `OUTPUT_SIZE, from_softmax_diff, from_softmax_diff_pk)

approx_softmax_comb i_act_3 (
    .x_pk(to_softmax_pk),
    .res_pk(from_softmax_pk)
);
approx_softmax_diff_comb i_act_diff_3 (
    .x_pk(to_softmax_pk),
    .res_pk(from_softmax_diff_pk)
);

assign fp_out = g_layer3[0].fp_out;
assign bp_s23 = g_layer3[0].bp_out;
assign w_out = w_out_c01 | w_out_c12 | w_out_c23;

endgenerate

endmodule

