////////////////////////////////////////////////////////////////////////////////
// AS501
// Final Project
// Mux 2 to 1
////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024 by Smart Energy-Efficient Design Lab. (SEED), KAIST
// All rights reserved.
//
//                            Written by Hyungjoon Bae (jo_on@kaist.ac.kr)
//                            Supervised by Wanyeong Jung (wanyeong@kaist.ac.kr)
////////////////////////////////////////////////////////////////////////////////

module MUX2TO1 #(
    parameter DWidth = 32
)(
    // Mux inputs
    input   logic   [DWidth-1:0]    data0_i,
    input   logic   [DWidth-1:0]    data1_i,
    input   logic                   select_i,
    // Mux output
    output  logic   [DWidth-1:0]    data_o
);

    always_comb begin
        unique case (select_i)
            1'b0:    data_o = data0_i;
            default: data_o = data1_i;
        endcase
    end

endmodule