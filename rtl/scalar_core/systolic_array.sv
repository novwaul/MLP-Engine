module SYSTOLIC_ARRAY
#(
    parameter  Size          = 8,
    parameter  DataBitwidth  = 8,
    parameter  OpWidth       = 5,
    localparam Rows          = Size,
    localparam Cols          = Size,
    localparam DSize         = Size+Size,
    localparam MSize         = Size*Size
)
(
    input  logic                    clk,
    input  logic                    rstn,
    input  logic                    bias_ready_i,
    input  logic                    data_ready_i,
    input  logic [DataBitwidth-1:0] data_i, // LB -> Load Partial Sums, LH -> Weights & Inputs
    input  logic                    data_req,
    input  logic [OpWidth-1:0]      op, //MULH -> MAC, MULHU -> ACT
    output logic [DataBitwidth-1:0] data_o // SB -> Store Partial Sums
);
    logic [DataBitwidth-1:0] registers[DSize];
    logic [2*DataBitwidth-1:0] partial_sums[MSize];
    logic [2*DataBitwidth-1:0] systolic_cell_out[MSize];

    logic op_ready;
    logic [$clog2(MSize)-1:0] pidx[Rows];
    logic [$clog2(MSize)-1:0] init[Rows];
    logic [$clog2(DSize)-1:0] sidx;
    logic [$clog2(MSize)-1:0] ridx;
    
    logic update_psum;
    logic keeper;
    logic data_ready [MSize];
   
    assign op_ready = (~op[OpWidth-1]) & op[OpWidth-2] & (~op[OpWidth-3]) & op[OpWidth-5]; // 01001, 01011
    
    initial begin
        for (int i = 0; i < Rows; i++) begin             
            init[i] <= Cols*i;                 
        end  
    end

    // REG                                                              
    always_ff @(posedge clk or negedge rstn) begin                       //       [0]w0  [1]w1  [2]w2  [3]w3
        if (!rstn) begin // initialize                                   // [4]i0   PE     PE     PE     PE
            for (int i = 0; i < DSize; i++) begin                        // [5]i1   PE     PE     PE     PE  
                registers[i] <= '0;                                      // [6]i2   PE     PE     PE     PE
            end                                                          // [7]i3   PE     PE     PE     PE
        end else if (data_ready_i) begin // store weight and input                    
            registers[sidx] <= data_i;                                                                             
        end else begin
            registers <= registers;        
        end
    end                                                                         

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin                                           
            for (int i = 0; i < MSize; i++) begin
                partial_sums[i] <= 'd0;
            end
        end else if (bias_ready_i) begin
            for (int i = 0; i < Rows; i++) begin                              
                partial_sums[pidx[i]] <= {{DataBitwidth{1'b0}}, data_i};
            end  
        end else if (data_ready[0]) begin
            for (int i = 0; i < MSize; i++) begin
                partial_sums[i] <= systolic_cell_out[i];
            end
        end else begin
            partial_sums <= partial_sums;
        end
    end

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            update_psum <= 1'b1;
            keeper <= 1'b0;
        end else if (data_ready[0] & !keeper) begin
            update_psum <= 1'b0;    
            keeper <= 1'b1;      
        end else if (op_ready) begin
            update_psum <= update_psum;
            keeper <= keeper;        
        end else begin
            update_psum <= 1'b1;   
            keeper <= 1'b0;
        end
    end

    // Psum Store State                    
    always_ff @(negedge bias_ready_i or negedge rstn) begin      
        if (!rstn) begin
            for (int i = 0; i < Rows; i++) begin             
                pidx[i] <= init[i];                 
            end  
        end else begin           
            for (int i = 0; i < Rows; i++) begin             
                pidx[i] <= pidx[i] + 'd1;                 
            end  
        end
    end

    // Store State  
    always_ff @(negedge data_ready_i or negedge rstn) begin      
        if (!rstn) begin
            sidx <= 'd0;
        end else begin           
            sidx <= sidx + 'd1;
        end
    end

    // Read State
    always_ff @(negedge data_req  or negedge rstn) begin    
        if (!rstn) begin
            ridx <= 'd0;
        end else begin             
            ridx <= ridx + 'd1;
        end
    end


    // Arithmetic
    generate
        genvar i, j;
        for(i = 0; i < Rows; i++) begin
            for(j = 0; j < Cols; j++) begin
                SYSTOLIC_ARRAY_CELL #(.DataBitwidth(DataBitwidth), .OpWidth(OpWidth)) PE (
                    .clk(clk),
                    .rstn(rstn),
                    .op_ready(op_ready & update_psum),
                    .op(op),
                    .input_data_i(registers[Cols+i]),
                    .weight_data_i(registers[j]),
                    .psum_data_i(partial_sums[Cols*i+j]),
                    .psum_data_o(systolic_cell_out[Cols*i+j]),
                    .data_ready_o(data_ready[Cols*i+j])
                );
            end
        end
    endgenerate


    // Return
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            data_o <= 'd0;
        end else begin
            if (partial_sums[ridx][2*DataBitwidth-1] > 'd0) begin
                data_o <= {DataBitwidth{1'b1}};
            end else begin
                data_o <= partial_sums[ridx][2*DataBitwidth-2:DataBitwidth-1] + partial_sums[ridx][DataBitwidth-2];
            end
        end
    end

endmodule

module SYSTOLIC_ARRAY_CELL
#(
    parameter DataBitwidth           = 8,
    parameter OpWidth                = 5,
    localparam DSize                 = 2*DataBitwidth
)           
(
    input logic                        clk,
    input logic                        rstn,
    input logic                        op_ready,
    input logic   [OpWidth-1:0]        op,
    input logic   [DataBitwidth-1:0]   input_data_i,
    input logic   [DataBitwidth-1:0]   weight_data_i,
    input logic   [2*DataBitwidth-1:0] psum_data_i,
    output logic  [2*DataBitwidth-1:0] psum_data_o,
    output logic                       data_ready_o
);
    localparam a_width = DataBitwidth;
    localparam b_width = DataBitwidth;
    `include "DW_dp_mult_comb_function.inc"
    import pkg_opfunct3::*;

    logic [DSize-1:0] mul_result;
    
    always_comb begin
        if (op_ready) begin
            unique case(op)
                MULH: begin // mac
                    mul_result = DWF_dp_mult_comb(.a(weight_data_i), .a_tc(1), .b(input_data_i), .b_tc(0));
                    psum_data_o = mul_result + psum_data_i;
                    data_ready_o = 'd1;
                end
                MULHU: begin // leave only positives (act)
                    psum_data_o = ($signed(psum_data_i) > $signed('d0)) ? psum_data_i : 'd0;
                    data_ready_o = 'd1;
                end
                default: begin
                    psum_data_o = 'd0;
                    data_ready_o = 'd1;
                end
            endcase
        end else begin
            psum_data_o = 'd0;
            data_ready_o = 'd0;
        end
    end
endmodule
