////////////////////////////////////////////////////////////////////////////////
// AS501
// Final Project
// Control and Status Registers (CSRs)
////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024 by Smart Energy-Efficient Design Lab. (SEED), KAIST
// All rights reserved.
//
//                            Written by Hyungjoon Bae (jo_on@kaist.ac.kr)
//                            Supervised by Wanyeong Jung (wanyeong@kaist.ac.kr)
////////////////////////////////////////////////////////////////////////////////

module CSR #(
    parameter DWidth = 32,
    parameter AWidth = 12
)(
    // Basic signals
    input   logic                   clk_i,
    input   logic                   rst_ni,
    // Special signals
    input   logic   [DWidth*2-1:0]  cycle_i,
    input   logic   [DWidth*2-1:0]  instret_i,
    // Read and Write signals
    input   logic   [AWidth-1:0]    read_addr_i,
    input   logic   [AWidth-1:0]    write_addr_i,
    input   logic   [DWidth-1:0]    write_data_i,
    input   logic                   write_en_i,
    // Read data
    output  logic   [DWidth-1:0]    read_data_o
);

////////////////////////////////////////////////////////////////////////////////
//  Latched read data
    logic   [DWidth-1:0]            latched_rdata;

    D_FF #(.DWidth(DWidth), .RValue('0)) FF_RDATA (
        .clk_i                      (clk_i),
        .rst_ni                     (rst_ni),
        .write_en_i                 (1'b1),
        .write_data_i               (read_data_o),
        .read_data_o                (latched_rdata)
    );

////////////////////////////////////////////////////////////////////////////////
//  CSR
    // Machine cycle counter (mcycle, 0xB00, 64bit, MRW)
    // Upper 32 bits of mcycle (mcycleh, 0xB80, 32bit, MRW)
    logic   [DWidth*2-1:0]          mcycle;

    D_FF #(.DWidth(DWidth*2), .RValue('0)) FF_MCYCLE (
        .clk_i                      (clk_i),
        .rst_ni                     (rst_ni),
        .write_en_i                 (1'b1),
        .write_data_i               (cycle_i),
        .read_data_o                (mcycle)
    );

    // Machine instructions-retired counter (minstret, 0xB02, 64bit, MRW)
    // Upper 32 bits of minstret (minstreth, 0xB82, 32bit, MRW)
    logic   [DWidth*2-1:0]          minstret;

    D_FF #(.DWidth(DWidth*2), .RValue('0)) FF_MINSTRET (
        .clk_i                      (clk_i),
        .rst_ni                     (rst_ni),
        .write_en_i                 (1'b1),
        .write_data_i               (instret_i),
        .read_data_o                (minstret)
    );

    // Read Mux (Data selection logic)
    always_comb begin
        unique case (read_addr_i)
            'hB00:   read_data_o = mcycle[DWidth-1:0];
            'hB80:   read_data_o = mcycle[DWidth*2-1:DWidth];
            'hB02:   read_data_o = minstret[DWidth-1:0];
            'hB82:   read_data_o = minstret[DWidth*2-1:DWidth];
            default: read_data_o = latched_rdata;
        endcase
    end

////////////////////////////////////////////////////////////////////////////////

endmodule