////////////////////////////////////////////////////////////////////////////////
// AS501
// Final Project
// Arithmetic Logic Unit (ALU)
////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024 by Smart Energy-Efficient Design Lab. (SEED), KAIST
// All rights reserved.
//
//                            Written by Hyungjoon Bae (jo_on@kaist.ac.kr)
//                            Supervised by Wanyeong Jung (wanyeong@kaist.ac.kr)
////////////////////////////////////////////////////////////////////////////////

module ALU #(
    parameter DWidth  = 32,
    parameter OpWidth = 5,
    localparam ShWidth = $clog2(DWidth)
)(
    // ALU inputs
    input   logic   [DWidth-1:0]    a_i,
    input   logic   [DWidth-1:0]    b_i,
    input   logic   [OpWidth-1:0]   op_sel_i,
    // ALU outputs
    output  logic   [DWidth-1:0]    res_o,
    output  logic                   zero_o
);
    import pkg_opfunct3::*;

////////////////////////////////////////////////////////////////////////////////
//  Multiplier
//  Pin description
//  a:      Multiplier
//  a_tc:   Two's complement control for multiplier, 0 = unsigned, 1 = signed
//          MULHU: 0,
//          MUL, MULH, MULHSU: 1
//  b:      Multiplicand
//  b_tc:   Two's complement control for multiplicand, 0 = unsigned, 1 = signed
//          MULHSU, MULHU: 0,
//          MUL, MULH: 1
//  return: a x b
////////////////////////////////////////////////////////////////////////////////
    localparam a_width = DWidth; // The function requires a parameter called a_width
    localparam b_width = DWidth; // The function requires a parameter called b_width
    `include "DW_dp_mult_comb_function.inc"

    logic   [DWidth*2-1:0]          mul_result;

    assign  mul_result = DWF_dp_mult_comb (
                            .a      (a_i),
                            .a_tc   (!(op_sel_i[1] & op_sel_i[0])),
                            .b      (b_i),
                            .b_tc   (!op_sel_i[1])
                         );

////////////////////////////////////////////////////////////////////////////////

    // ALU & Output mux
    always_comb begin
        unique case(op_sel_i)
            ADD:     res_o = a_i + b_i;
            SUB:     res_o = a_i - b_i;
            SLL:     res_o = a_i << b_i[ShWidth-1:0];
            SLT:     res_o = $signed(a_i) < $signed(b_i);
            SLTU:    res_o = a_i < b_i;
            XOR:     res_o = a_i ^ b_i;
            SRL:     res_o = a_i >> b_i[ShWidth-1:0];
            SRA:     res_o = $unsigned($signed(a_i) >>> b_i[ShWidth-1:0]);
            OR:      res_o = a_i | b_i;
            AND:     res_o = a_i & b_i;
            MUL:     res_o = mul_result[DWidth-1:0];
            MULHSU:  res_o = mul_result[DWidth*2-1:DWidth];
            default: res_o = '0;
        endcase
    end

    // Zero flag
    assign  zero_o  = ~(|res_o);

endmodule