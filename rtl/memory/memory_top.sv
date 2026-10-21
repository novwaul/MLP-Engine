////////////////////////////////////////////////////////////////////////////////
// AS501
// Final Project
// Memory TOP
////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024 by Smart Energy-Efficient Design Lab. (SEED), KAIST
// All rights reserved.
//
//                            Written by Hyungjoon Bae (jo_on@kaist.ac.kr)
//                                       Michal Gorywoda (hotwater@kaist.ac.kr)
//                            Supervised by Wanyeong Jung (wanyeong@kaist.ac.kr)
////////////////////////////////////////////////////////////////////////////////

module MEMORY_TOP #(
    parameter  DWidth        = '0,
    parameter  MemDepth      = '0,
    parameter  InitFile      = "",
    parameter  IMemStart     = '0,
    parameter  DMemStart     = '0,
    parameter  InputAddr     = '0,
    parameter  Fc1WAddr      = '0,
    parameter  Fc1BAddr      = '0,
    parameter  Fc2WAddr      = '0,
    parameter  Fc2BAddr      = '0,
    parameter  Fc3WAddr      = '0,
    parameter  Fc3BAddr      = '0,
    parameter  LabelAddr     = '0,
    parameter  ImageInitFile = "",
    parameter  Fc1WInitFile  = "",
    parameter  Fc1BInitFile  = "",
    parameter  Fc2WInitFile  = "",
    parameter  Fc2BInitFile  = "",
    parameter  Fc3WInitFile  = "",
    parameter  Fc3BInitFile  = "",
    parameter  LabelInitFile = "",
    localparam DelayCycles   = 'd4
)(
    input   logic                   clk_i,
    input   logic                   mclk_i,
    input   logic                   rst_ni,

    // Instruction Interface
    input   logic                   imem_req_i,
    input   logic                   imem_write_i,
    input   logic   [DWidth-1:0]    imem_addr_i,
    input   logic   [DWidth-1:0]    imem_wdata_i,
    output  logic                   imem_ready_o,
    output  logic   [DWidth-1:0]    imem_rdata_o,

    // Data Interface
    input   logic                   dmem_req_i,
    input   logic                   dmem_write_i,
    input   logic   [DWidth-1:0]    dmem_addr_i,
    input   logic   [DWidth-1:0]    dmem_wdata_i,
    output  logic                   dmem_ready_o,
    output  logic   [DWidth-1:0]    dmem_rdata_o
);
    logic   [DWidth-1:0]            mem[0:MemDepth[DWidth-1:2]-1];

    // Delay counter
    logic   [$clog2(DelayCycles)-1:0] delay_cnt;
    always @(posedge mclk_i) begin
        if (!rst_ni) begin
            delay_cnt <= '0;
        end else if (dmem_req_i || imem_req_i) begin
            if (delay_cnt == $unsigned(DelayCycles-1)) begin
                delay_cnt <= '0;
            end else begin
                delay_cnt <= delay_cnt + 1;
            end
        end
    end

    // VCS doesn't allow always_ff with $readmemh
    // So always_ff is replaced with always
    always @(posedge clk_i) begin
        if (!rst_ni) begin
            dmem_rdata_o <= '0;
            dmem_ready_o <= 1'b0;
            imem_rdata_o <= '0;
            imem_ready_o <= 1'b0;
        end else if (dmem_req_i && (delay_cnt == $unsigned(DelayCycles-1))) begin
            if (dmem_write_i) begin
                mem[dmem_addr_i[DWidth-1:2]] <= dmem_wdata_i;
            end else begin
                dmem_rdata_o <= mem[dmem_addr_i[DWidth-1:2]];
            end
            dmem_ready_o <= 1'b1;
        end else if (imem_req_i && (delay_cnt == $unsigned(DelayCycles-1))) begin
            imem_rdata_o <= mem[imem_addr_i[DWidth-1:2]];
            imem_ready_o <= 1'b1;
        end else begin
            dmem_ready_o <= 1'b0;
            imem_ready_o <= 1'b0;
        end
    end

`ifdef SIM
    initial begin
        for (int i = 0; i < MemDepth[DWidth-1:2]-1; ++i) begin
            mem[i] = 'h0;
        end
        $readmemh(InitFile,      mem, IMemStart[DWidth-1:2]);
        $readmemh(ImageInitFile, mem, InputAddr[DWidth-1:2]);
        $readmemh(Fc1WInitFile,  mem, Fc1WAddr[DWidth-1:2]);
        $readmemh(Fc1BInitFile,  mem, Fc1BAddr[DWidth-1:2]);
        $readmemh(Fc2WInitFile,  mem, Fc2WAddr[DWidth-1:2]);
        $readmemh(Fc2BInitFile,  mem, Fc2BAddr[DWidth-1:2]);
        $readmemh(Fc3WInitFile,  mem, Fc3WAddr[DWidth-1:2]);
        $readmemh(Fc3BInitFile,  mem, Fc3BAddr[DWidth-1:2]);
        $readmemh(LabelInitFile, mem, LabelAddr[DWidth-1:2]);
    end
`endif

endmodule