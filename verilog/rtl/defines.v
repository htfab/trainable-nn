// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2022 Tamas Hubai

`default_nettype none

// numbers are represented as fixed-point fractions
// with an integral part of INT_WIDTH bits
// and a fractional part of FRAC_WIDTH bits
// (64 bits are an overkill here, but simulations were run on a 64-bit platform)
`define INT_WIDTH 40
`define FRAC_WIDTH 24
`define NUM_WIDTH (`INT_WIDTH + `FRAC_WIDTH)

// multiplication is the main bottleneck in the circuit complexity
// so we recude integer & fractional widths for multiplications
// (this didn't significantly affect learning speed in our tests)

`define MUL_INT_WIDTH 6
`define PRE_MUL_FRAC_WIDTH 12
`define POST_MUL_FRAC_WIDTH 16

// number of neurons in input, hidden 1, hidden 2 & output layers
`define INPUT_SIZE 3
`define HIDDEN1_SIZE 2
`define HIDDEN2_SIZE 2
`define OUTPUT_SIZE 3

// bits required to describe the sizes above
`define INDEX_WIDTH 10

// power of 1/2 used an the slope of leaky ReLU's negative part
`define LEAK_SHIFT 7

// power of 1/2 used as the learning rate
`define LEARN_SHIFT 7

// macros for passing bus arrays to modules
`define PACK_ARRAY_INTERNAL(WIDTH,LEN,SRC,DEST,VAR) \
    generate genvar VAR; \
    for (VAR=0; VAR<(LEN); VAR=VAR+1) begin \
        assign DEST[((WIDTH)*VAR+((WIDTH)-1)):((WIDTH)*VAR)] = SRC[VAR][((WIDTH)-1):0]; \
    end \
    endgenerate
`define PACK_ARRAY(WIDTH,LEN,SRC,DEST) `PACK_ARRAY_INTERNAL(WIDTH,LEN,SRC,DEST,pa_``SRC)
`define UNPACK_ARRAY_INTERNAL(WIDTH,LEN,DEST,SRC,VAR) \
    generate genvar VAR; \
    for (VAR=0; VAR<(LEN); VAR=VAR+1) begin \
        assign DEST[VAR][((WIDTH)-1):0] = SRC[((WIDTH)*VAR+(WIDTH-1)):((WIDTH)*VAR)]; \
    end \
    endgenerate
`define UNPACK_ARRAY(WIDTH,LEN,SRC,DEST) `UNPACK_ARRAY_INTERNAL(WIDTH,LEN,SRC,DEST,ua_``SRC)

