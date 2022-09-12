// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2022 Tamas Hubai

`default_nettype none

module trainable_nn (
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);

    assign io_out = {(`MPRJ_IO_PADS){1'b0}};
    assign io_oeb = {(`MPRJ_IO_PADS){1'b0}};

    assign irq = 3'b000;	// Unused

    wire clk = (~la_oenb[0]) ? la_data_in[0]: wb_clk_i;
    wire rst = (~la_oenb[1]) ? la_data_in[1]: wb_rst_i;

    wire use_wbs = wbs_cyc_i & wbs_stb_i;
    wire use_la_addr = &~la_oenb[31:8];
    wire use_la_data_in = &~la_oenb[95:32];

    wire [23:0] addr = use_la_addr ? la_data_in[31:8] : wbs_adr_i[23:0];
    wire [63:0] data_in = (use_la_addr & use_la_data_in) ? la_data_in[95:32] : {20'b0, wbs_dat_i, 12'b0};
    wire we = (use_la_addr & use_la_data_in) | (use_wbs & wbs_we_i);
    wire [63:0] data_out;
    assign la_data_out = {32'b0, data_out, 32'b0};
    assign wbs_dat_o = data_out[43:12];

    neural_interface i_ni (
        .clk,
        .addr,
        .data_in,
        .we,
        .data_out
    );

    always @(posedge clk) begin
        wbs_ack_o <= (~rst) & use_wbs;
    end

endmodule

