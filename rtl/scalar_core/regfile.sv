////////////////////////////////////////////////////////////////////////////////
// AS501
// Final Project
// Register File
////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024 by Smart Energy-Efficient Design Lab. (SEED), KAIST
// All rights reserved.
//
//                            Written by Hyungjoon Bae (jo_on@kaist.ac.kr)
//                            Supervised by Wanyeong Jung (wanyeong@kaist.ac.kr)
////////////////////////////////////////////////////////////////////////////////

module REGFILE #(
    parameter DWidth   = 32,
    parameter NumofReg = 32,
    localparam AWidth  = $clog2(NumofReg)
)(
    // Basic signals
    input   logic                   clk_i,
    input   logic                   rst_ni,
    // Read and Write signals
    input   logic   [AWidth-1:0]    read1_addr_i,
    input   logic   [AWidth-1:0]    read2_addr_i,
    input   logic   [AWidth-1:0]    write_addr_i,
    input   logic   [DWidth-1:0]    write_data_i,
    input   logic                   write_en_i,
    // Read data
    output  logic   [DWidth-1:0]    read1_data_o,
    output  logic   [DWidth-1:0]    read2_data_o
);

    // Register array
    logic   [DWidth-1:0]            GPR[0:NumofReg-1];

    // GPR[0] is hardwired ground
    assign  GPR[0] = '0;

    // Read Operation
    assign  read1_data_o = GPR[read1_addr_i];
    assign  read2_data_o = GPR[read2_addr_i];

    // Generate write enable signal for each flip flop
    logic                           write_en[1:NumofReg-1];

    always_comb begin
        // begin: iterate over write enable
        for (int unsigned i = 1; i < NumofReg; i = i + 1) begin
            if ((i == write_addr_i) && write_en_i) begin
                write_en[i] = 1'b1;
            end else begin
                write_en[i] = 1'b0;
            end
        end
        // end: iterate over write enable
    end

    // Write Operation
    // begin: iterate over gpr
    for (genvar j = 1; j < NumofReg; j = j + 1) begin : gen_gpr
        D_FF #(.DWidth(DWidth), .RValue('0)) FF_GPR(
            .clk_i                  (clk_i),
            .rst_ni                 (rst_ni),
            .write_en_i             (write_en[j]),
            .write_data_i           (write_data_i),
            .read_data_o            (GPR[j])
        );
    end
    // end: iterate over gpr

endmodule