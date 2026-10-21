////////////////////////////////////////////////////////////////////////////////
// AS501
// Final Project
// Scalar Core
////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024 by Smart Energy-Efficient Design Lab. (SEED), KAIST
// All rights reserved.
//
//                            Written by Hyungjoon Bae (jo_on@kaist.ac.kr)
//                            Supervised by Wanyeong Jung (wanyeong@kaist.ac.kr)
////////////////////////////////////////////////////////////////////////////////

module SCALAR_CORE #(
    parameter DWidth             = 32,
    localparam NumofReg          = 32,
    localparam AWidth            = $clog2(NumofReg),
    localparam CWidth            = 12,
    localparam OpWidth           = 5,
    localparam SAWidth           = 9,
    localparam SASize            = 4
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
    output  logic                   dmem_write_o,
    // Scratch Pad
    output  logic                   scratch_req,
    output  logic                   scratch_write
);

////////////////////////////////////////////////////////////////////////////////
// Cycle Counter
    logic   [DWidth*2-1:0]          cycle;

    COUNTER #(.DWidth(DWidth*2), .RValue('0)) COUNTER_CYCLE(
        .clk_i                      (clk_i),
        .rst_ni                     (rst_ni),
        .cnt_en_i                   (1'b1),
        .cnt_done_o                 (),
        .cnt_data_o                 (cycle)
    );

////////////////////////////////////////////////////////////////////////////////
// This core is designed in a non-pipelined manner
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// Instruction Fetch
    logic   [DWidth-3:0]            inc_iaddr;

    assign inc_iaddr = imem_addr_o[DWidth-1:2] + {{(DWidth-3){1'b0}}, 1'b1};

    logic   [DWidth-1:0]            branch_addr;
    logic                           dec_br_en;
    logic   [DWidth-1:0]            pc_iaddr_d;

    MUX2TO1 #(.DWidth(DWidth)) MUX_PC(
        .data0_i                    ({inc_iaddr, 2'b0}),
        .data1_i                    (branch_addr),
        .select_i                   (dec_br_en),
        .data_o                     (pc_iaddr_d)
    );

    logic                           dec_pc_en;
    logic   [DWidth-1:0]            pc_iaddr_q;

    D_FF #(.DWidth(DWidth), .RValue('0)) FF_PC (
        .clk_i                      (clk_i),
        .rst_ni                     (rst_ni),
        .write_en_i                 (dec_pc_en),
        .write_data_i               (pc_iaddr_d),
        .read_data_o                (pc_iaddr_q)
    );

    logic                           dec_iaddr_en;
    logic   [DWidth-1:0]            ir_addr_q;

    D_FF #(.DWidth(DWidth), .RValue('0)) FF_IADDR(
        .clk_i                      (clk_i),
        .rst_ni                     (rst_ni),
        .write_en_i                 (dec_iaddr_en),
        .write_data_i               (pc_iaddr_q),
        .read_data_o                (ir_addr_q)
    );

    assign  imem_addr_o = pc_iaddr_q;

////////////////////////////////////////////////////////////////////////////////
// Instruction Decode & Register File read & CSR read
    logic   [1:0]                   dec_a_sel;
    logic   [DWidth-1:0]            dec_b_imm;
    logic   [1:0]                   dec_b_sel;
    logic   [OpWidth-1:0]           dec_alu_op_sel;
    logic                           alu_zero;
    logic   [2:0]                   dec_ls_ext_sel;
    logic   [1:0]                   dec_rf_write_sel;
    logic                           dec_br_sel;

    logic   [AWidth-1:0]            dec_read1_addr;
    logic   [AWidth-1:0]            dec_read2_addr;
    logic   [AWidth-1:0]            dec_write_addr;
    logic                           dec_write_en;

    logic                           dec_cwrite_sel;
    logic   [CWidth-1:0]            dec_cread_addr;
    logic   [CWidth-1:0]            dec_cwrite_addr;
    logic                           dec_cwrite_en;

    logic   [DWidth*2-1:0]          dec_instret;

    logic                           lb;
    logic                           lbu;
    logic                           lh;
    logic                           lhu;
    logic                           sb;
    logic                           sh;
    logic                           ld_st;

    DECODER #(.DWidth(DWidth), .OpWidth(OpWidth), .NumofReg(NumofReg), .CWidth(CWidth)) DECODER(
        .clk_i                      (clk_i),
        .rst_ni                     (rst_ni),
        .pc_en_o                    (dec_pc_en),
        .iaddr_en_o                 (dec_iaddr_en),
        .imem_ready_i               (imem_ready_i),
        .imem_rdata_i               (imem_rdata_i),
        .imem_read_o                (imem_req_o),
        .br_sel_o                   (dec_br_sel),
        .pc_br_en_o                 (dec_br_en),
        .alu_b_imm_o                (dec_b_imm),
        .alu_a_sel_o                (dec_a_sel),
        .alu_b_sel_o                (dec_b_sel),
        .alu_op_sel_o               (dec_alu_op_sel),
        .flag_zero_i                (alu_zero),
        .ls_ext_sel_o               (dec_ls_ext_sel),
        .rf_write_sel_o             (dec_rf_write_sel),
        .rf_write_addr_o            (dec_write_addr),
        .rf_write_en_o              (dec_write_en),
        .rf_read1_addr_o            (dec_read1_addr),
        .rf_read2_addr_o            (dec_read2_addr),
        .csr_write_sel_o            (dec_cwrite_sel),
        .csr_write_en_o             (dec_cwrite_en),
        .csr_read_addr_o            (dec_cread_addr),
        .csr_write_addr_o           (dec_cwrite_addr),
        .csr_instret_o              (dec_instret),
        .dmem_ready_i               (dmem_ready_i),
        .dmem_req_o                 (dmem_req_o),
        .dmem_write_o               (dmem_write_o),
        .lb                         (lb),
        .lbu                        (lbu),
        .lh                         (lh),
        .lhu                        (lhu),
        .sb                         (sb),
        .sh                         (sh),
        .ld_st                      (ld_st)
    );

    logic   [DWidth-1:0]            rf_write_data;
    logic   [DWidth-1:0]            rf_read1_data;
    logic   [DWidth-1:0]            rf_read2_data;

    REGFILE #(.DWidth(DWidth), .NumofReg(NumofReg)) SRF(
        .clk_i                      (clk_i),
        .rst_ni                     (rst_ni),
        .read1_addr_i               (dec_read1_addr),
        .read2_addr_i               (dec_read2_addr),
        .write_addr_i               (dec_write_addr),
        .write_data_i               (rf_write_data),
        .write_en_i                 (dec_write_en),
        .read1_data_o               (rf_read1_data),
        .read2_data_o               (rf_read2_data)
    );

    logic   [DWidth-1:0]            csr_write_data;
    logic   [DWidth-1:0]            csr_read_data;

    CSR #(.DWidth(DWidth), .AWidth(CWidth)) CSR(
        .clk_i                      (clk_i),
        .rst_ni                     (rst_ni),
        .cycle_i                    (cycle),
        .instret_i                  (dec_instret),
        .read_addr_i                (dec_cread_addr),
        .write_addr_i               (dec_cwrite_addr),
        .write_data_i               (csr_write_data),
        .write_en_i                 (dec_cwrite_en),
        .read_data_o                (csr_read_data)
    );

////////////////////////////////////////////////////////////////////////////////
// Execute & Address calculation
    // Execute
    logic   [DWidth-1:0]            alu_a;
    logic   [DWidth-1:0]            alu_b;

    MUX4TO1 #(.DWidth(DWidth)) MUX_ALU_A(
        .data0_i                    (rf_read1_data),
        .data1_i                    (ir_addr_q),
        .data2_i                    (csr_read_data),
        .data3_i                    (~rf_read1_data),
        .select_i                   (dec_a_sel),
        .data_o                     (alu_a)
    );

    MUX4TO1 #(.DWidth(DWidth)) MUX_ALU_B(
        .data0_i                    (rf_read2_data),
        .data1_i                    (dec_b_imm),
        .data2_i                    (csr_read_data),
        .data3_i                    (~dec_b_imm),
        .select_i                   (dec_b_sel),
        .data_o                     (alu_b)
    );

    logic   [DWidth-1:0]            alu_res;

    ALU #(.DWidth(DWidth), .OpWidth(OpWidth)) ALU(
        .a_i                        (alu_a),
        .b_i                        (alu_b),
        .op_sel_i                   (dec_alu_op_sel),
        .res_o                      (alu_res),
        .zero_o                     (alu_zero)
    );

    // Address calculation
    logic   [DWidth-1:0]            br_inc_pc;

    assign br_inc_pc = dec_b_imm + ir_addr_q;

    MUX2TO1 #(.DWidth(DWidth)) MUX_BR(
        .data0_i                    (alu_res),
        .data1_i                    (br_inc_pc),
        .select_i                   (dec_br_sel),
        .data_o                     (branch_addr)
    );

    logic   [SAWidth-1:0]           systolic_data_o;
    logic                           systolic_bias_write_en;
    logic                           systolic_data_write_en;
    logic                           systolic_read_en;

    assign systolic_bias_write_en = dec_write_en & lb;
    assign systolic_data_write_en = dec_write_en & (lh | lhu);
    assign systolic_read_en = dmem_write_o & (sb | lbu);
    assign scratch_write = dmem_write_o & (sh | lbu);
    assign scratch_req = dmem_req_o & ld_st & (sh | lbu | lb | lh);

    SYSTOLIC_ARRAY #(.Size(SASize), .DataBitwidth(SAWidth), .OpWidth(OpWidth)) ACCELERATOR(
        .clk                        (clk_i),
        .rstn                       (rst_ni),
        .bias_ready_i               (systolic_bias_write_en),
        .data_ready_i               (systolic_data_write_en), 
        .data_i                     ({rf_write_data[SAWidth-1:1], 1'b1}), // LB -> Load Partial Sums & Weights & Inputs
        .data_req                   (systolic_read_en),
        .data_o                     (systolic_data_o),                    // SB -> Store Partial Sums
        .op                         (dec_alu_op_sel)                      //MULH -> MAC, MULHU -> ACT
    );

////////////////////////////////////////////////////////////////////////////////
// Access data memory
    // Address
    assign  dmem_addr_o = alu_res;
    localparam EmptyWidth = DWidth-SAWidth;

    // Data write
    MUX5TO1 #(.DWidth(DWidth)) MUX_LD(
        .data0_i                    ({{(EmptyWidth){1'b0}}, systolic_data_o}),                     // From Systolic Array (SB)
        .data1_i                    (rf_read2_data[31:0]),                                         // Signed Halfword
        .data2_i                    (rf_read2_data[31:0]),                                         // Word
        .data3_i                    ({{24{1'b0}}, rf_read2_data[7:0]}),                            // Unsigned Byte
        .data4_i                    ({{16{1'b0}}, rf_read2_data[15:0]}),                           // Unsigned Halfword
        .select_i                   (dec_ls_ext_sel),
        .data_o                     (dmem_wdata_o)
    );

    logic   [DWidth-1:0]            data_rdata;

    // Data read
    MUX3TO1 #(.DWidth(DWidth)) MUX_ST( 
        .data0_i                    (dmem_rdata_i[31:0]),   // Signed Byte -> Systolic Array Bias
        .data1_i                    (dmem_rdata_i[31:0]),   // Signed Halfword -> -> Systolic Array Input & Weight
        .data2_i                    (dmem_rdata_i[31:0]),                           
        .select_i                   (dec_ls_ext_sel[1:0]),
        .data_o                     (data_rdata)
    );

////////////////////////////////////////////////////////////////////////////////
// Write back
    MUX4TO1 #(.DWidth(DWidth)) MUX_WB(
        .data0_i                    (alu_res),
        .data1_i                    (data_rdata), 
        .data2_i                    ({imem_addr_o[DWidth-1:2], 2'b0}),
        .data3_i                    (csr_read_data),
        .select_i                   (dec_rf_write_sel),
        .data_o                     (rf_write_data)
    );

    MUX2TO1 #(.DWidth(DWidth)) MUX_WB_CSR(
        .data0_i                    (alu_res),
        .data1_i                    (dec_b_imm),
        .select_i                   (dec_cwrite_sel),
        .data_o                     (csr_write_data)
    );

////////////////////////////////////////////////////////////////////////////////

endmodule