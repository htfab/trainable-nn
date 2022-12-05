// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2022 Tamas Hubai

`default_nettype none

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

