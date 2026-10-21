////////////////////////////////////////////////////////////////////////////////
// AS501
// Final Project
// Counter
////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024 by Smart Energy-Efficient Design Lab. (SEED), KAIST
// All rights reserved.
//
//                            Written by Hyungjoon Bae (jo_on@kaist.ac.kr)
//                            Supervised by Wanyeong Jung (wanyeong@kaist.ac.kr)
////////////////////////////////////////////////////////////////////////////////

module COUNTER #(
    parameter DWidth = 64,
    parameter RValue = '0,
    parameter FValue = (1 << 64) - 1
)(
    // Basic signals
    input   logic                   clk_i,
    input   logic                   rst_ni,
    // Counting signals
    input   logic                   cnt_en_i,
    // Read signal
    output  logic                   cnt_done_o,
    output  logic   [DWidth-1:0]    cnt_data_o
);
    import pkg_bool::*;

    // Synchronous for only cycle
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            cnt_data_o <= RValue;
            cnt_done_o <= FALSE;
        end else if (cnt_en_i) begin
            if (cnt_data_o == $unsigned(FValue)) begin
                cnt_done_o <= TRUE;
            end else begin
                cnt_done_o <= FALSE;
            end
            cnt_data_o <= cnt_data_o + 1'b1;
        end
    end

endmodule