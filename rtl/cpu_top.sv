////////////////////////////////////////////////////////////////////////////////
// AS501
// Final Project
// CPU Top Module
////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024 by Smart Energy-Efficient Design Lab. (SEED), KAIST
// All rights reserved.
//
//                            Written by Hyungjoon Bae (jo_on@kaist.ac.kr)
//                            Supervised by Wanyeong Jung (wanyeong@kaist.ac.kr)
////////////////////////////////////////////////////////////////////////////////

module CPU_TOP #(
    parameter DWidth = 32
)(
    // Basic signals
    input   logic                   clk_i,
    input   logic                   rst_ni,
    // Instruction interface
    input   logic                   imem_ready_i,
    input   logic   [DWidth-1:0]    imem_rdata_i,
    output  logic   [DWidth-1:0]    imem_addr_o,
    output  logic                   imem_req_o,
    // Data interface
    input   logic                   dmem_ready_i,
    input   logic   [DWidth-1:0]    dmem_rdata_i,
    output  logic   [DWidth-1:0]    dmem_wdata_o,
    output  logic   [DWidth-1:0]    dmem_addr_o,
    output  logic                   dmem_req_o,
    output  logic                   dmem_write_o
);
    logic                           icache_read;
    logic   [DWidth-1:0]            icache_addr;
    logic   [DWidth-1:0]            icache_rdata;
    logic                           icache_hit;

    INSTR_CACHE #(.DWidth(DWidth)) ICACHE(
        .clk_i                      (clk_i),
        .rst_ni                     (rst_ni),
        .read_i                     (icache_read),
        .addr_i                     (icache_addr),
        .imem_rdata_i               (imem_rdata_i),
        .imem_ready_i               (imem_ready_i),
        .imem_addr_o                (imem_addr_o),
        .imem_req_o                 (imem_req_o),
        .instr_o                    (icache_rdata),
        .hit_o                      (icache_hit)
    );

    logic                           req_o;
    logic                           ready_i;     
    logic   [DWidth-1:0]            rdata_i;

    logic   [DWidth-1:0]            spad_rdata_o;
    logic                           spad_ready_o;

    logic                           spad_req_o;
    logic                           spad_write_o;
    
    assign dmem_req_o = req_o & (~spad_req_o);
    assign rdata_i = spad_ready_o ? spad_rdata_o : dmem_rdata_i;
    assign ready_i = dmem_ready_i | spad_ready_o;

    SCALAR_CORE #(.DWidth(DWidth)) SCORE(
        .clk_i                      (clk_i),
        .rst_ni                     (rst_ni),
        .imem_ready_i               (icache_hit),
        .imem_rdata_i               (icache_rdata),
        .imem_addr_o                (icache_addr),
        .imem_req_o                 (icache_read),
        .dmem_ready_i               (ready_i),
        .dmem_rdata_i               (rdata_i),
        .dmem_wdata_o               (dmem_wdata_o),
        .dmem_addr_o                (dmem_addr_o),
        .dmem_req_o                 (req_o),
        .dmem_write_o               (dmem_write_o),
        .scratch_req                (spad_req_o),
        .scratch_write              (spad_write_o)
    );

    SCRATCH_PAD #(.DWidth(DWidth)) SPAD(
        .clk_i                      (clk_i),
        .rst_ni                     (rst_ni),
        .request                    (spad_req_o),
        .addr_i                     (dmem_addr_o),
        .write_data_i               (dmem_wdata_o),
        .write_i                    (spad_write_o),
        .read_data_o                (spad_rdata_o),
        .ready_o                    (spad_ready_o)
    );

endmodule