////////////////////////////////////////////////////////////////////////////////
// AS501
// Final Project
// Core Package
////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024 by Smart Energy-Efficient Design Lab. (SEED), KAIST
// All rights reserved.
//
//                            Written by Hyungjoon Bae (jo_on@kaist.ac.kr)
//                            Supervised by Wanyeong Jung (wanyeong@kaist.ac.kr)
////////////////////////////////////////////////////////////////////////////////

package pkg_bool;
    localparam      TRUE   = 1'b1;
    localparam      FALSE  = 1'b0;
endpackage

package pkg_rw;
    localparam      READ   = 1'b0;
    localparam      WRITE  = 1'b1;
endpackage

package pkg_opfunct3;
    // funct3: {instr[30], instr[25], instr[14:12]}
    localparam      ADD    = 5'b0_0000;
    localparam      SUB    = 5'b1_0000;
    localparam      SLL    = 5'b0_0001;
    localparam      SLT    = 5'b0_0010;
    localparam      SLTU   = 5'b0_0011;
    localparam      XOR    = 5'b0_0100;
    localparam      SRL    = 5'b0_0101;
    localparam      SRA    = 5'b1_0101;
    localparam      OR     = 5'b0_0110;
    localparam      AND    = 5'b0_0111;
    localparam      MUL    = 5'b0_1000;
    localparam      MULH   = 5'b0_1001; //9
    localparam      MULHU  = 5'b0_1011; //b
    localparam      MULHSU = 5'b0_1010;
endpackage