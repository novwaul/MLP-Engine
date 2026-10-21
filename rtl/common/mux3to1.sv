////////////////////////////////////////////////////////////////////////////////
// AS501
// Final Project
// Mux 3 to 1
////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024 by Smart Energy-Efficient Design Lab. (SEED), KAIST
// All rights reserved.
//
//                            Written by Hyungjoon Bae (jo_on@kaist.ac.kr)
//                            Supervised by Wanyeong Jung (wanyeong@kaist.ac.kr)
////////////////////////////////////////////////////////////////////////////////

module MUX3TO1 #(
    parameter DWidth = 32
)(
    // Mux inputs
    input   logic   [DWidth-1:0]    data0_i,
    input   logic   [DWidth-1:0]    data1_i,
    input   logic   [DWidth-1:0]    data2_i,
    input   logic   [1:0]           select_i,
    // Mux output
    output  logic   [DWidth-1:0]    data_o
);

    always_comb begin
        unique case (select_i)
            2'b00:   data_o = data0_i;
            2'b01:   data_o = data1_i;
            2'b10:   data_o = data2_i;
            default: data_o = '0;
        endcase
    end

endmodule