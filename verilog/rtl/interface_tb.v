// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2022 Tamas Hubai

`default_nettype none

// testbench for the single neural_interface module in interface.v

module neural_interface_tb ();

reg clk;
reg [23:0] addr;
reg [`NUM_WIDTH-1:0] data_in;
reg we;
wire [`NUM_WIDTH-1:0] data_out;

neural_interface dut (
    .clk,
    .addr,
    .data_in,
    .we,
    .data_out
);

generate genvar i; genvar j;

for (i=0; i<`INPUT_SIZE; i=i+1) begin
    for (j=0; j<`HIDDEN1_SIZE; j=j+1) begin
        initial begin
            dut.i_nn.g_syn01_o[i].g_syn01_i[j].i_syn01.w <= 0;
        end
    end
end
for (i=0; i<`HIDDEN1_SIZE; i=i+1) begin
    for (j=0; j<`HIDDEN2_SIZE; j=j+1) begin
        initial begin
            dut.i_nn.g_syn12_o[i].g_syn12_i[j].i_syn12.w <= 0;
        end
    end
end
for (i=0; i<`HIDDEN2_SIZE; i=i+1) begin
    for (j=0; j<`OUTPUT_SIZE; j=j+1) begin
        initial begin
            dut.i_nn.g_syn23_o[i].g_syn23_i[j].i_syn23.w <= 0;
        end
    end
end
for (i=0; i<`INPUT_SIZE; i=i+1) begin
    initial begin
        dut.a0[i] <= 1;
    end
end
for (i=0; i<`OUTPUT_SIZE; i=i+1) begin
    initial begin
        dut.i_nn.g_layer3[i].i_neu_3.a <= 2;
        dut.g3[i] <= 3;
    end
end

endgenerate

initial begin
    clk <= 0;
    we <= 0;
    $monitor("time %4t addr %24b data_in %64b we %1b data_out %64b", $time, addr, data_in, we, data_out);
    #5 clk<=1; #5 clk<=0;
    addr <= 24'b0010_0000000111_0000000011;
    #5 clk<=1; #5 clk<=0;
    data_in <= 15;
    we <= 1;
    #5 clk<=1; #5 clk<=0;
    we <= 0;
    #5 clk<=1; #5 clk<=0;
    #5 clk<=1; #5 clk<=0;
    addr <= 24'b0100_0000000000_0000000101;
    data_in <= 33;
    we <= 1;
    #5 clk<=1; #5 clk<=0;
    we <= 0;
    #5 clk<=1; #5 clk<=0;
    addr <= 24'b0101_0000000000_0000000101;
    data_in <= 17;
    we <= 1;
    #5 clk<=1; #5 clk<=0;
    we <= 0;
    #5 clk<=1; #5 clk<=0;
    addr <= 24'b0110_0000000000_0000000101;
    data_in <= 9;
    we <= 1;
    #5 clk<=1; #5 clk<=0;
    we <= 0;
    #5 clk<=1; #5 clk<=0;
    dut.fp_out_hold <= 0;
    addr <= 24'b0111_0000000000_0000000000;
    data_in <= 1;
    we <= 1;
    #5 clk<=1; #5 clk<=0;
    we <= 0;
    #5 clk<=1; #5 clk<=0;
    #5 clk<=1; #5 clk<=0;
    #5 clk<=1; #5 clk<=0;
    #5 clk<=1; #5 clk<=0;
    #5 clk<=1; #5 clk<=0;
    #5 clk<=1; #5 clk<=0;
    data_in <= 0;
    we <= 1;
    #5 clk<=1; #5 clk<=0;
    we <= 0;
    #5 clk<=1; #5 clk<=0;
    dut.bp_out_hold <= 0;
    addr <= 24'b0111_0000000000_0000000001;
    data_in <= 1;
    we <= 1;
    #5 clk<=1; #5 clk<=0;
    we <= 0;
    #5 clk<=1; #5 clk<=0;
    #5 clk<=1; #5 clk<=0;
    #5 clk<=1; #5 clk<=0;
    #5 clk<=1; #5 clk<=0;
    #5 clk<=1; #5 clk<=0;
    #5 clk<=1; #5 clk<=0;
    data_in <= 0;
    we <= 1;
    #5 clk<=1; #5 clk<=0;
    we <= 0;
    #5 clk<=1; #5 clk<=0;
    addr <= 24'b0111_0000000000_0000000010;
    #5 clk<=1; #5 clk<=0;
    addr <= 24'b0111_0000000000_0000000011;
    #5 clk<=1; #5 clk<=0;
    #5 clk<=1; #5 clk<=0;
    $finish;
end

endmodule

