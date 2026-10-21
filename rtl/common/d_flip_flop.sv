////////////////////////////////////////////////////////////////////////////////
// AS501
// Final Project
// D Flip Flop
////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024 by Smart Energy-Efficient Design Lab. (SEED), KAIST
// All rights reserved.
//
//                            Written by Hyungjoon Bae (jo_on@kaist.ac.kr)
//                            Supervised by Wanyeong Jung (wanyeong@kaist.ac.kr)
////////////////////////////////////////////////////////////////////////////////

module D_FF #(
    parameter DWidth = 32,
    parameter RValue = '0
)(
    // Basic signals
    input   logic                   clk_i,
    input   logic                   rst_ni,
    // Write signals
    input   logic                   write_en_i,
    input   logic   [DWidth-1:0]    write_data_i,
    // Read signal
    output  logic   [DWidth-1:0]    read_data_o
);

    // Synchronous for both cycle and reset
    always_ff @(posedge clk_i) begin
        if (!rst_ni) begin
            read_data_o <= RValue;
        end else if (write_en_i) begin
            read_data_o <= write_data_i;
        end
    end

endmodule