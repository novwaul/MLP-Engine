////////////////////////////////////////////////////////////////////////////////
// AS501
// Final Project
// Decoder
////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024 by Smart Energy-Efficient Design Lab. (SEED), KAIST
// All rights reserved.
//
//                            Written by Hyungjoon Bae (jo_on@kaist.ac.kr)
//                            Supervised by Wanyeong Jung (wanyeong@kaist.ac.kr)
////////////////////////////////////////////////////////////////////////////////

module DECODER #(
    parameter DWidth   = 32,
    parameter OpWidth  = 5,
    parameter NumofReg = 32,
    parameter CWidth   = 12,
    localparam AWidth  = $clog2(NumofReg)
)(
    // Basic signals
    input   logic                   clk_i,
    input   logic                   rst_ni,
    // Program counter
    output  logic                   pc_en_o,
    output  logic                   iaddr_en_o,
    // Instruction memory
    input   logic                   imem_ready_i,
    input   logic   [DWidth-1:0]    imem_rdata_i,
    output  logic                   imem_read_o,
    // Branch
    output  logic                   br_sel_o,
    output  logic                   pc_br_en_o,
    // ALU
    output  logic   [DWidth-1:0]    alu_b_imm_o,
    output  logic   [1:0]           alu_a_sel_o,
    output  logic   [1:0]           alu_b_sel_o,
    output  logic   [OpWidth-1:0]   alu_op_sel_o,
    input   logic                   flag_zero_i,
    // MUX_LD_ST
    output  logic   [2:0]           ls_ext_sel_o,
    // RF
    output  logic   [1:0]           rf_write_sel_o,
    output  logic   [AWidth-1:0]    rf_write_addr_o,
    output  logic                   rf_write_en_o,
    output  logic   [AWidth-1:0]    rf_read1_addr_o,
    output  logic   [AWidth-1:0]    rf_read2_addr_o,
    // CSR
    output  logic                   csr_write_sel_o,
    output  logic                   csr_write_en_o,
    output  logic   [CWidth-1:0]    csr_read_addr_o,
    output  logic   [CWidth-1:0]    csr_write_addr_o,
    output  logic   [DWidth*2-1:0]  csr_instret_o,
    // Data memory
    input   logic                   dmem_ready_i,
    output  logic                   dmem_req_o,
    output  logic                   dmem_write_o,
    // Systolic Array & Scratch Pad
    output  logic                   lb,
    output  logic                   lbu,
    output  logic                   lh,
    output  logic                   lhu,
    output  logic                   sb,
    output  logic                   sh,
    output  logic                   ld_st
);
    import pkg_bool::*;
    import pkg_rw::*;
    import pkg_opfunct3::*;

    // MUX_ALU_A
    localparam      READ1_DATA      = 2'b00;
    localparam      PROGRAM_COUNTER = 2'b01;
    localparam      CSR_RDATA       = 2'b10;
    localparam      N_READ1_DATA    = 2'b11;

    // MUX_ALU_B
    localparam      READ2_DATA      = 2'b00;
    localparam      IMMEDIATE       = 2'b01;
    localparam      N_IMMEDIATE     = 2'b11;

    // MUX_BR
    localparam      PC_ALU          = 1'b0;
    localparam      PC_IMM          = 1'b1;

    // MUX_WB
    localparam      WB_ALU_PC       = 2'b00;
    localparam      WB_DMEM         = 2'b01;
    localparam      WB_JALx         = 2'b10;
    localparam      WB_CSR          = 2'b11;

    // MUX_WB_CSR
    localparam      WB_CSR_ALU      = 1'b0;
    localparam      WB_CSR_IMM      = 1'b1;

    // RV32I Opcode
    localparam      LUI             = 7'b0110111;
    localparam      AUIPC           = 7'b0010111;
    localparam      JAL             = 7'b1101111;
    localparam      JALR            = 7'b1100111;
    localparam      BRANCH          = 7'b1100011;
    localparam      LOAD            = 7'b0000011;
    localparam      STORE           = 7'b0100011;
    localparam      IMM             = 7'b0010011;
    localparam      REG             = 7'b0110011;
    localparam      CSR             = 7'b1110011;

    // Branch type
    localparam      BEQ             = 3'b000;
    localparam      BNE             = 3'b001;
    localparam      BLT             = 3'b100;
    localparam      BLTU            = 3'b110;
    localparam      BGE             = 3'b101;
    localparam      BGEU            = 3'b111;

    // CSR type
    localparam     CSRRW            = 3'b001;
    localparam     CSRRS            = 3'b010;
    localparam     CSRRC            = 3'b011;
    localparam     CSRRWI           = 3'b101;
    localparam     CSRRSI           = 3'b110;
    localparam     CSRRCI           = 3'b111;

////////////////////////////////////////////////////////////////////////////////
// Mealy machine
    // FSM states
    typedef enum logic [1:0] { // A 2-bit enumerated type
        StFetch, StExecute, StDmem, StJump
    } dec_state_e;

    dec_state_e                     dec_state_d, dec_state_q;

    //logic                           ld_st;
    logic                           jp_br;
    logic                           rf_wb_en;
    logic                           csr_wb_en;
    logic                           dmem_rw;

    // Combinational logic for next state & logic for outputs
    always_comb begin
        unique case (dec_state_q)
            StFetch: begin
                // If instruction is ready, update pc and go to execute
                // else stay in fetch
                dec_state_d      = imem_ready_i ? StExecute : StFetch;
                imem_read_o      = !imem_ready_i;
                pc_en_o          = dec_state_d inside {StExecute};
                iaddr_en_o       = dec_state_d inside {StExecute};
                rf_write_en_o    = FALSE;
                csr_write_en_o   = FALSE;
                pc_br_en_o       = FALSE;
                dmem_write_o     = FALSE;
                dmem_req_o       = FALSE;
            end
            StExecute: begin
                // If the decoded instruction is load or store, go to dmem
                // else if it is jump, go to jump
                // else go to fetch
                dec_state_d      = ld_st ? StDmem : jp_br ? StJump : StFetch;
                imem_read_o      = dec_state_d inside {StFetch};
                pc_en_o          = jp_br ? TRUE : FALSE;
                iaddr_en_o       = FALSE;
                rf_write_en_o    = ld_st ? FALSE : rf_wb_en ? TRUE : FALSE;
                csr_write_en_o   = csr_wb_en ? TRUE : FALSE;
                pc_br_en_o       = jp_br ? TRUE : FALSE;
                dmem_write_o     = ld_st ? dmem_rw : FALSE;
                dmem_req_o       = ld_st ? TRUE : FALSE;
            end
            StDmem: begin
                // If memory access done, update pc and go to fetch
                // else stay in dmem
                dec_state_d      = dmem_ready_i ? StFetch : StDmem;
                imem_read_o      = dec_state_d inside {StFetch};
                pc_en_o          = FALSE;
                iaddr_en_o       = FALSE;
                rf_write_en_o    = dmem_ready_i ? rf_wb_en ? TRUE : FALSE : FALSE;
                csr_write_en_o   = FALSE;
                pc_br_en_o       = FALSE;
                dmem_write_o     = dmem_ready_i ? FALSE : dmem_rw;
                dmem_req_o       = dmem_ready_i ? FALSE : TRUE;
            end
            default: begin // StJump
                // Wait 1 cycle for branch address
                dec_state_d      = StFetch;
                imem_read_o      = dec_state_d inside {StFetch};
                pc_en_o          = FALSE;
                iaddr_en_o       = FALSE;
                rf_write_en_o    = FALSE;
                csr_write_en_o   = FALSE;
                pc_br_en_o       = FALSE;
                dmem_write_o     = FALSE;
                dmem_req_o       = FALSE;
            end
        endcase
    end

    // FSM register
    D_FF #(.DWidth(2), .RValue(StFetch)) FF_DEC_STATE(
        .clk_i                      (clk_i),
        .rst_ni                     (rst_ni),
        .write_en_i                 (1'b1),
        .write_data_i               (dec_state_d[1:0]),
        .read_data_o                (dec_state_q[1:0])
    );

    // Retirement Counter
    COUNTER #(.DWidth(DWidth*2), .RValue('0)) COUNTER_INSTRET(
        .clk_i                      (clk_i),
        .rst_ni                     (rst_ni),
        .cnt_en_i                   (!dec_state_q inside {StFetch} && dec_state_d inside {StFetch}),
        .cnt_done_o                 (),
        .cnt_data_o                 (csr_instret_o)
    );

////////////////////////////////////////////////////////////////////////////////
// Decode logic
    always_comb begin
        unique case (imem_rdata_i[6:0])
            LUI: begin
                alu_b_imm_o          = {imem_rdata_i[31:12], 12'h0};
                alu_a_sel_o          = '0;                     // Doesn't matter
                alu_b_sel_o          = IMMEDIATE;              // Imm
                alu_op_sel_o         = ADD;                    // Imm
                rf_read1_addr_o      = '0;                     // GPR[0]
                rf_read2_addr_o      = '0;                     // Doesn't matter - Imm
                rf_write_addr_o      = imem_rdata_i[11:7];
                rf_write_sel_o       = WB_ALU_PC;              // ALU
                br_sel_o             = '0;                     // Doesn't matter - Not branch
                jp_br                = FALSE;
                rf_wb_en             = TRUE;
                ld_st                = FALSE;
                dmem_rw              = '0;                     // Doesn't matter - Not LD/ST
                ls_ext_sel_o         = '0;                     // Doesn't matter - Not LD/ST
                csr_wb_en            = FALSE;
                csr_read_addr_o      = '0;                     // Doesn't matter - Not CSR
                csr_write_addr_o     = '0;                     // Doesn't matter - Not CSR
                csr_write_sel_o      = '0;                     // Doesn't matter - Not CSR
                lb                   = '0;
                lbu                  = '0;
                lh                   = '0;
                lhu                  = '0;
                sb                   = '0;
                sh                   = '0;
            end
            AUIPC: begin
                alu_b_imm_o          = {imem_rdata_i[31:12], 12'h0};
                alu_a_sel_o          = PROGRAM_COUNTER;        // PC
                alu_b_sel_o          = IMMEDIATE;              // Imm
                alu_op_sel_o         = ADD;                    // PC + Imm
                rf_read1_addr_o      = '0;                     // Doesn't matter - PC
                rf_read2_addr_o      = '0;                     // Doesn't matter - Imm
                rf_write_addr_o      = imem_rdata_i[11:7];
                rf_write_sel_o       = WB_ALU_PC;              // ALU
                br_sel_o             = '0;                     // Doesn't matter - Not branch
                jp_br                = FALSE;
                rf_wb_en             = TRUE;
                ld_st                = FALSE;
                dmem_rw              = '0;                     // Doesn't matter - Not LD/ST
                ls_ext_sel_o         = '0;                     // Doesn't matter - Not LD/ST
                csr_wb_en            = FALSE;
                csr_read_addr_o      = '0;                     // Doesn't matter - Not CSR
                csr_write_addr_o     = '0;                     // Doesn't matter - Not CSR
                csr_write_sel_o      = '0;                     // Doesn't matter - Not CSR
                lb                   = '0;
                lbu                  = '0;
                lh                   = '0;
                lhu                  = '0;
                sb                   = '0;
                sh                   = '0;
            end
            JAL: begin
                alu_b_imm_o          = {{11{imem_rdata_i[31]}}, imem_rdata_i[31], imem_rdata_i[19:12], imem_rdata_i[20], imem_rdata_i[30:21], 1'b0};
                alu_a_sel_o          = PROGRAM_COUNTER;        // PC
                alu_b_sel_o          = IMMEDIATE;              // Offset
                alu_op_sel_o         = ADD;                    // PC + Offset
                rf_read1_addr_o      = '0;                     // Doesn't matter - PC
                rf_read2_addr_o      = '0;                     // Doesn't matter - Imm
                rf_write_addr_o      = imem_rdata_i[11:7];
                rf_write_sel_o       = WB_JALx;                // Link register
                br_sel_o             = PC_ALU;                 // ALU
                jp_br                = TRUE;
                rf_wb_en             = TRUE;
                ld_st                = FALSE;
                dmem_rw              = '0;                     // Doesn't matter - Not LD/ST
                ls_ext_sel_o         = '0;                     // Doesn't matter - Not LD/ST
                csr_wb_en            = FALSE;
                csr_read_addr_o      = '0;                     // Doesn't matter - Not CSR
                csr_write_addr_o     = '0;                     // Doesn't matter - Not CSR
                csr_write_sel_o      = '0;                     // Doesn't matter - Not CSR
                lb                   = '0;
                lbu                  = '0;
                lh                   = '0;
                lhu                  = '0;
                sb                   = '0;
                sh                   = '0;
            end
            JALR: begin
                alu_b_imm_o          = {{20{imem_rdata_i[31]}}, imem_rdata_i[31:20]};
                alu_a_sel_o          = READ1_DATA;             // GPR[rs1]
                alu_b_sel_o          = IMMEDIATE;              // Offset
                alu_op_sel_o         = ADD;                    // GPR[rs1] + Offset
                rf_read1_addr_o      = imem_rdata_i[19:15];
                rf_read2_addr_o      = '0;                     // Doesn't matter - Imm
                rf_write_addr_o      = imem_rdata_i[11:7];
                rf_write_sel_o       = WB_JALx;                // Link register
                br_sel_o             = PC_ALU;                 // ALU
                jp_br                = TRUE;
                rf_wb_en             = TRUE;
                ld_st                = FALSE;
                dmem_rw              = '0;                     // Doesn't matter - Not LD/ST
                ls_ext_sel_o         = '0;                     // Doesn't matter - Not LD/ST
                csr_wb_en            = FALSE;
                csr_read_addr_o      = '0;                     // Doesn't matter - Not CSR
                csr_write_addr_o     = '0;                     // Doesn't matter - Not CSR
                csr_write_sel_o      = '0;                     // Doesn't matter - Not CSR
                lb                   = '0;
                lbu                  = '0;
                lh                   = '0;
                lhu                  = '0;
                sb                   = '0;
                sh                   = '0;
            end
            BRANCH: begin
                alu_b_imm_o          = {{19{imem_rdata_i[31]}}, imem_rdata_i[31],imem_rdata_i[7], imem_rdata_i[30:25], imem_rdata_i[11:8], 1'b0};
                alu_a_sel_o          = READ1_DATA;             // GPR[rs1]
                alu_b_sel_o          = READ2_DATA;             // GPR[rs2]
                rf_read1_addr_o      = imem_rdata_i[19:15];
                rf_read2_addr_o      = imem_rdata_i[24:20];
                rf_write_addr_o      = '0;                     // Not WB
                rf_write_sel_o       = '0;                     // Doesn't matter - Not WB
                br_sel_o             = PC_IMM;                 // Jump to PC + imm calculated externally (not ALU)
                lb                   = '0;
                lbu                  = '0;
                lh                   = '0;
                lhu                  = '0;
                sb                   = '0;
                sh                   = '0;
                unique case (imem_rdata_i[14:12])
                    BEQ: begin
                        alu_op_sel_o = SUB;
                        jp_br        = flag_zero_i;
                    end
                    BNE: begin
                        alu_op_sel_o = SUB;
                        jp_br        = !flag_zero_i;
                    end
                    BLT: begin
                        alu_op_sel_o = SLT;
                        jp_br        = !flag_zero_i;
                    end
                    BLTU: begin
                        alu_op_sel_o = SLTU;
                        jp_br        = !flag_zero_i;
                    end
                    BGE: begin
                        alu_op_sel_o = SLT;
                        jp_br        = flag_zero_i;
                    end
                    BGEU: begin
                        alu_op_sel_o = SLTU;
                        jp_br        = flag_zero_i;
                    end
                    default: begin                             // Not reachable
                        alu_op_sel_o = '0;                     // Doesn't matter - Not use zero flag
                        jp_br        = FALSE;
                    end
                endcase
                rf_wb_en             = FALSE;
                ld_st                = FALSE;
                dmem_rw              = '0;                     // Doesn't matter - Not LD/ST
                ls_ext_sel_o         = '0;                     // Doesn't matter - Not LD/ST
                csr_wb_en            = FALSE;
                csr_read_addr_o      = '0;                     // Doesn't matter - Not CSR
                csr_write_addr_o     = '0;                     // Doesn't matter - Not CSR
                csr_write_sel_o      = '0;                     // Doesn't matter - Not CSR
            end
            LOAD: begin
                alu_b_imm_o          = {{20{imem_rdata_i[31]}}, imem_rdata_i[31:20]};
                alu_a_sel_o          = READ1_DATA;             // GPR[rs1]
                alu_b_sel_o          = IMMEDIATE;              // Offset
                alu_op_sel_o         = ADD;                    // GPR[rs1] + Offset
                rf_read1_addr_o      = imem_rdata_i[19:15];
                rf_read2_addr_o      = '0;                     // Doesn't matter - Imm
                rf_write_addr_o      = imem_rdata_i[11:7];
                rf_write_sel_o       = WB_DMEM;                // DMEM
                br_sel_o             = '0;                     // Doesn't matter - Not branch
                jp_br                = FALSE;
                rf_wb_en             = imem_rdata_i[14:12] != 3'b100 ? TRUE : FALSE;
                ld_st                = TRUE;
                dmem_rw              = imem_rdata_i[14:12] != 3'b100 ? READ : WRITE;
                ls_ext_sel_o         = imem_rdata_i[14:12] != 3'b100 ? imem_rdata_i[14:12] : 3'b000;
                csr_wb_en            = FALSE;
                csr_read_addr_o      = '0;                     // Doesn't matter - Not CSR
                csr_write_addr_o     = '0;                     // Doesn't matter - Not CSR
                csr_write_sel_o      = '0;                     // Doesn't matter - Not CSR
                lb                   = imem_rdata_i[14:12] == 3'b000;
                lbu                  = imem_rdata_i[14:12] == 3'b100;
                lh                   = imem_rdata_i[14:12] == 3'b001;
                lhu                  = imem_rdata_i[14:12] == 3'b101;
                sb                   = '0;
                sh                   = '0;
            end
            STORE: begin
                alu_b_imm_o          = {{20{imem_rdata_i[31]}}, imem_rdata_i[31:25], imem_rdata_i[11:7]};
                alu_a_sel_o          = READ1_DATA;             // GPR[rs1]
                alu_b_sel_o          = IMMEDIATE;              // Offset
                alu_op_sel_o         = ADD;                    // GPR[rs1] + Offset
                rf_read1_addr_o      = imem_rdata_i[19:15];
                rf_read2_addr_o      = imem_rdata_i[24:20];
                rf_write_addr_o      = '0;                     // Doesn't matter - Not WB
                rf_write_sel_o       = '0;                     // Doesn't matter - Not WB
                br_sel_o             = '0;                     // Doesn't matter - Not branch
                jp_br                = FALSE;
                rf_wb_en             = FALSE;
                ld_st                = TRUE;
                dmem_rw              = WRITE;
                ls_ext_sel_o         = imem_rdata_i[14:12];
                csr_wb_en            = FALSE;
                csr_read_addr_o      = '0;                     // Doesn't matter - Not CSR
                csr_write_addr_o     = '0;                     // Doesn't matter - Not CSR
                csr_write_sel_o      = '0;                     // Doesn't matter - Not CSR
                lb                   = '0;
                lbu                  = '0;
                lh                   = '0;
                lhu                  = '0;
                sb                   = imem_rdata_i[13:12] == 2'b00;
                sh                   = imem_rdata_i[13:12] == 2'b01;
            end
            IMM: begin
                unique case ({imem_rdata_i[30], imem_rdata_i[25], imem_rdata_i[14:12]})
                    SLL,
                    SRL,
                    SRA: begin
                        alu_b_imm_o  = {{20{1'b0}}, imem_rdata_i[24:20]};
                        alu_op_sel_o = {imem_rdata_i[30], imem_rdata_i[25], imem_rdata_i[14:12]};
                    end
                    default: begin
                        alu_b_imm_o  = {{20{imem_rdata_i[31]}}, imem_rdata_i[31:20]};
                        alu_op_sel_o = {2'b0, imem_rdata_i[14:12]};
                    end
                endcase
                alu_a_sel_o          = READ1_DATA;             // GPR[rs1]
                alu_b_sel_o          = IMMEDIATE;              // Imm
                rf_read1_addr_o      = imem_rdata_i[19:15];
                rf_read2_addr_o      = '0;                     // Doesn't matter - Imm
                rf_write_addr_o      = imem_rdata_i[11:7];
                rf_write_sel_o       = WB_ALU_PC;              // ALU
                br_sel_o             = '0;                     // Doesn't matter - Not branch
                jp_br                = FALSE;
                rf_wb_en             = TRUE;
                ld_st                = FALSE;
                dmem_rw              = '0;                     // Doesn't matter - Not LD/ST
                ls_ext_sel_o         = '0;                     // Doesn't matter - Not LD/ST
                csr_wb_en            = FALSE;
                csr_read_addr_o      = '0;                     // Doesn't matter - Not CSR
                csr_write_addr_o     = '0;                     // Doesn't matter - Not CSR
                csr_write_sel_o      = '0;                     // Doesn't matter - Not CSR
                lb                   = '0;
                lbu                  = '0;
                lh                   = '0;
                lhu                  = '0;
                sb                   = '0;
                sh                   = '0;
            end
            REG: begin
                alu_b_imm_o          = '0;                     // Doesn't matter - Not use IMM
                alu_a_sel_o          = READ1_DATA;             // GPR[rs1]
                alu_b_sel_o          = READ2_DATA;             // GPR[rs2]
                alu_op_sel_o         = {imem_rdata_i[30], imem_rdata_i[25], imem_rdata_i[14:12]};
                rf_read1_addr_o      = imem_rdata_i[19:15];
                rf_read2_addr_o      = imem_rdata_i[24:20];
                rf_write_addr_o      = imem_rdata_i[11:7];
                rf_write_sel_o       = WB_ALU_PC;              // ALU
                br_sel_o             = '0;                     // Doesn't matter - Not branch
                jp_br                = FALSE;
                rf_wb_en             = TRUE;
                ld_st                = FALSE;
                dmem_rw              = '0;                     // Doesn't matter - Not LD/ST
                ls_ext_sel_o         = '0;                     // Doesn't matter - Not LD/ST
                csr_wb_en            = FALSE;
                csr_read_addr_o      = '0;                     // Doesn't matter - Not CSR
                csr_write_addr_o     = '0;                     // Doesn't matter - Not CSR
                csr_write_sel_o      = '0;                     // Doesn't matter - Not CSR
                lb                   = '0;
                lbu                  = '0;
                lh                   = '0;
                lhu                  = '0;
                sb                   = '0;
                sh                   = '0;
            end
            CSR: begin
                rf_read2_addr_o      = '0;                     // Doesn't matter - Not use rs2
                rf_write_addr_o      = imem_rdata_i[11:7];
                rf_write_sel_o       = WB_CSR;                 // CSR
                br_sel_o             = '0;                     // Doesn't matter - Not branch
                jp_br                = FALSE;
                rf_wb_en             = TRUE;
                ld_st                = FALSE;
                dmem_rw              = '0;                     // Doesn't matter - Not LD/ST
                ls_ext_sel_o         = '0;                     // Doesn't matter - Not LD/ST
                csr_read_addr_o      = imem_rdata_i[31:20];
                csr_write_addr_o     = imem_rdata_i[31:20];
                lb                   = '0;
                lbu                  = '0;
                lh                   = '0;
                lhu                  = '0;
                sb                   = '0;
                sh                   = '0;
                unique case (imem_rdata_i[14:12])
                    CSRRW: begin
                        alu_b_imm_o     = '0;                              // 0
                        alu_a_sel_o     = READ1_DATA;                      // GPRx[rs1]
                        alu_b_sel_o     = IMMEDIATE;                       // Imm
                        alu_op_sel_o    = ADD;                             // GPRx[rs1] + Imm
                        rf_read1_addr_o = imem_rdata_i[19:15];
                        csr_wb_en       = TRUE;
                        csr_write_sel_o = WB_CSR_ALU;
                    end
                    CSRRS: begin
                        alu_b_imm_o     = '0;                              // Doesn't matter - Not use Imm
                        alu_a_sel_o     = READ1_DATA;                      // GPRx[rs1]
                        alu_b_sel_o     = CSR_RDATA;                       // CSRs[csr]
                        alu_op_sel_o    = OR;                              // GPRx[rs1] | CSRs[csr]
                        rf_read1_addr_o = imem_rdata_i[19:15];
                        csr_wb_en       = (imem_rdata_i[19:15] == '0) ? FALSE : TRUE;
                        csr_write_sel_o = WB_CSR_ALU;
                    end
                    CSRRC: begin
                        alu_b_imm_o     = '0;
                        alu_a_sel_o     = N_READ1_DATA;                    // ~GPRx[rs1]
                        alu_b_sel_o     = CSR_RDATA;                       // CSRs[csr]
                        alu_op_sel_o    = AND;                             // ~GPRx[rs1] & CSRs[csr]
                        rf_read1_addr_o = imem_rdata_i[19:15];
                        csr_wb_en       = (imem_rdata_i[19:15] == '0) ? FALSE : TRUE;
                        csr_write_sel_o = WB_CSR_ALU;
                    end
                    CSRRWI: begin
                        alu_b_imm_o     = {27'd0, imem_rdata_i[19:15]};    // Imm
                        alu_a_sel_o     = '0;                              // Doesn't matter - Not use alu
                        alu_b_sel_o     = '0;                              // Doesn't matter - Not use alu
                        alu_op_sel_o    = '0;                              // Doesn't matter - Not use alu
                        rf_read1_addr_o = '0;                              // Doesn't matter - Not use rs1
                        csr_wb_en       = TRUE;
                        csr_write_sel_o = WB_CSR_IMM;
                    end
                    CSRRSI: begin
                        alu_b_imm_o     = {27'd0, imem_rdata_i[19:15]};    // Imm
                        alu_a_sel_o     = CSR_RDATA;                       // CSRs[csr]
                        alu_b_sel_o     = IMMEDIATE;                       // Imm
                        alu_op_sel_o    = OR;                              // CSRs[csr] | Imm
                        rf_read1_addr_o = '0;                              // Doesn't matter - Not use rs1
                        csr_wb_en       = (imem_rdata_i[19:15] == '0) ? FALSE : TRUE;
                        csr_write_sel_o = WB_CSR_ALU;
                    end
                    CSRRCI: begin
                        alu_b_imm_o     = {27'd0, imem_rdata_i[19:15]};    // Imm
                        alu_a_sel_o     = CSR_RDATA;                       // CSRs[csr]
                        alu_b_sel_o     = N_IMMEDIATE;                     // ~Imm
                        alu_op_sel_o    = AND;                             // GPRx[rs1] + Imm
                        rf_read1_addr_o = imem_rdata_i[19:15];
                        csr_wb_en       = (imem_rdata_i[19:15] == '0) ? FALSE : TRUE;
                        csr_write_sel_o = WB_CSR_ALU;
                    end
                    default: begin // Unreachable
                        alu_b_imm_o     = '0;
                        alu_a_sel_o     = '0;
                        alu_b_sel_o     = '0;
                        alu_op_sel_o    = '0;
                        rf_read1_addr_o = '0;
                        csr_wb_en       = FALSE;
                        csr_write_sel_o = '0;
                    end
                endcase
            end
            // The first instruction (all zero case)
            default: begin
                alu_b_imm_o          = '0;
                alu_a_sel_o          = '0;
                alu_b_sel_o          = '0;
                alu_op_sel_o         = '0;
                rf_read1_addr_o      = '0;
                rf_read2_addr_o      = '0;
                rf_write_addr_o      = '0;
                rf_write_sel_o       = '0;
                br_sel_o             = PC_ALU;
                jp_br                = FALSE;
                rf_wb_en             = FALSE;
                ld_st                = FALSE;
                dmem_rw              = '0;
                ls_ext_sel_o         = '0;
                csr_wb_en            = FALSE;
                csr_read_addr_o      = '0;
                csr_write_addr_o     = '0;
                csr_write_sel_o      = '0;
                lb                   = '0;
                lbu                  = '0;
                lh                   = '0;
                lhu                  = '0;
                sb                   = '0;
                sh                   = '0;
            end
        endcase
    end
endmodule