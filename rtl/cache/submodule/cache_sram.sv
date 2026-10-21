////////////////////////////////////////////////////////////////////////////////
// AS501
// Final Project
// Cache SRAM
////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024 by Smart Energy-Efficient Design Lab. (SEED), KAIST
// All rights reserved.
//
//                            Written by Hyungjoon Bae (jo_on@kaist.ac.kr)
//                            Supervised by Wanyeong Jung (wanyeong@kaist.ac.kr)
////////////////////////////////////////////////////////////////////////////////

module CACHE_SRAM #(
    parameter DWidth = 56,
    parameter Depth  = 128,
    localparam Index = $clog2(Depth)
)(
    input   logic                   clk_i,
    input   logic                   csb_i,
    input   logic                   oeb_i,
    input   logic                   web_i,
    input   logic   [Index-1:0]     addr_i,
    input   logic   [DWidth-1:0]    data_i,
    output  logic   [DWidth-1:0]    data_o
);

    // SAED32 doesn't support flexible wordline widths SRAM
    // So, a 56-bit wordline is emulated using 8-bit + 48-bit SRAMs
    SRAM1RW128x8 SRAM8(
        .CE                         (clk_i),
        .CSB                        (csb_i),
        .WEB                        (web_i),
        .OEB                        (oeb_i),
        .A                          (addr_i),
        .I                          (data_i[DWidth-1:DWidth-8]),
        .O                          (data_o[DWidth-1:DWidth-8])
    );

    SRAM1RW128x48 SRAM48(
        .CE                         (clk_i),
        .CSB                        (csb_i),
        .WEB                        (web_i),
        .OEB                        (oeb_i),
        .A                          (addr_i),
        .I                          (data_i[DWidth-9:0]),
        .O                          (data_o[DWidth-9:0])
    );

endmodule