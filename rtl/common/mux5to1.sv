////////////////////////////////////////////////////////////////////////////////
// AS501
// Final Project
// Mux 5 to 1
////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024 by Smart Energy-Efficient Design Lab. (SEED), KAIST
// All rights reserved.
//
//                            Written by Hyungjoon Bae (jo_on@kaist.ac.kr)
//                            Supervised by Wanyeong Jung (wanyeong@kaist.ac.kr)
////////////////////////////////////////////////////////////////////////////////

module MUX5TO1 #(
    parameter DWidth = 32
)(
    // Mux inputs
    input   logic   [DWidth-1:0]    data0_i,
    input   logic   [DWidth-1:0]    data1_i,
    input   logic   [DWidth-1:0]    data2_i,
    input   logic   [DWidth-1:0]    data3_i,
    input   logic   [DWidth-1:0]    data4_i,
    input   logic   [2:0]           select_i,
    // Mux output
    output  logic   [DWidth-1:0]    data_o
);

    always_comb begin
        unique case (select_i)
            3'b000:  data_o = data0_i;
            3'b001:  data_o = data1_i;
            3'b010:  data_o = data2_i;
            3'b011:  data_o = data3_i;
            3'b100:  data_o = data4_i;
            default: data_o = '0;
        endcase
    end

endmodule