module SCRATCH_PAD #(
    parameter  DWidth = 32,
    localparam InDWidth = 8,
    localparam Depth = 4*1024,
    localparam SramDepth = 1024,
    localparam Index = $clog2(Depth)
)(
    // Basic signals
    input   logic                   clk_i,
    input   logic                   rst_ni,
    // From scalar core
    input   logic                   request,
    input   logic   [DWidth-1:0]    addr_i,
    // From scalar core
    input   logic   [DWidth-1:0]    write_data_i,
    input   logic                   write_i,
    // To scalar core
    output  logic   [DWidth-1:0]    read_data_o,
    output  logic                   ready_o
);
    import pkg_bool::*;

    logic [InDWidth-1:0]    data_cache0;
    logic [InDWidth-1:0]    data_cache1;
    logic [InDWidth-1:0]    data_cache2;
    logic [InDWidth-1:0]    data_cache3;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            ready_o <= 'd0;
        end else if (request) begin
            ready_o <= 'd1;
        end else begin
            ready_o <= 'd0;
        end
    end

    always_comb begin
        if (addr_i[Index+1:Index] == 'd0) begin 
            read_data_o = {{(DWidth-InDWidth-1){1'b0}}, data_cache0, 1'b0};
        end else if (addr_i[Index+1:Index] == 'd1) begin
            read_data_o = {{(DWidth-InDWidth-1){1'b0}}, data_cache1, 1'b0};
        end else if (addr_i[Index+1:Index] == 'd2) begin
            read_data_o = {{(DWidth-InDWidth-1){1'b0}}, data_cache2, 1'b0};
        end else if (addr_i[Index+1:Index] == 'd3) begin
            read_data_o = {{(DWidth-InDWidth-1){1'b0}}, data_cache3, 1'b0};
        end else begin
            read_data_o = 'd0;
        end
    end

////////////////////////////////////////////////////////////////////////////////

`ifdef SIM
    // Hold time delay
    wire                            #0.55   cen_d_0   = request && (addr_i[Index+1:Index] == 'd0);
    wire                            #0.55   cen_d_1   = request && (addr_i[Index+1:Index] == 'd1);
    wire                            #0.55   cen_d_2   = request && (addr_i[Index+1:Index] == 'd2);
    wire                            #0.55   cen_d_3   = request && (addr_i[Index+1:Index] == 'd3);
    wire                            #0.41   wen_d     = write_i;
    wire                            #0.55   oen_d     = !write_i;
    wire    [Index+1-2-2:0]         #0.53   addr_d    = addr_i[Index-1:2];
    wire    [InDWidth-1:0]          #0.52   wdata_d   = write_data_i[InDWidth:1];

    SCRATCH_PAD_SRAM #(.Depth(SramDepth), .DWidth(InDWidth)) SCRATCH_PAD_0(
        .clk_i                      (clk_i),
        .csb_i                      (!cen_d_0),
        .web_i                      (!wen_d),
        .addr_i                     (addr_d),
        .oeb_i                      (!oen_d),
        .data_i                     (wdata_d),
        .data_o                     (data_cache0)
    );
    SCRATCH_PAD_SRAM #(.Depth(SramDepth), .DWidth(InDWidth)) SCRATCH_PAD_1(
        .clk_i                      (clk_i),
        .csb_i                      (!cen_d_1),
        .web_i                      (!wen_d),
        .addr_i                     (addr_d),
        .oeb_i                      (!oen_d),
        .data_i                     (wdata_d),
        .data_o                     (data_cache1)
    );
    SCRATCH_PAD_SRAM #(.Depth(SramDepth), .DWidth(InDWidth)) SCRATCH_PAD_2(
        .clk_i                      (clk_i),
        .csb_i                      (!cen_d_2),
        .web_i                      (!wen_d),
        .addr_i                     (addr_d),
        .oeb_i                      (!oen_d),
        .data_i                     (wdata_d),
        .data_o                     (data_cache2)
    );
    SCRATCH_PAD_SRAM #(.Depth(SramDepth), .DWidth(InDWidth)) SCRATCH_PAD_3(
        .clk_i                      (clk_i),
        .csb_i                      (!cen_d_3),
        .web_i                      (!wen_d),
        .addr_i                     (addr_d),
        .oeb_i                      (!oen_d),
        .data_i                     (wdata_d),
        .data_o                     (data_cache3)
    );
`else // For synthesis
SCRATCH_PAD_SRAM #(.Depth(SramDepth), .DWidth(InDWidth)) SCRATCH_PAD_0(
        .clk_i                      (clk_i),
        .csb_i                      (!request && (addr_i[Index+1:Index] == 'd0)),
        .web_i                      (!write_i),
        .addr_i                     (addr_i[Index-1:2]),
        .oeb_i                      (!oen),
        .data_i                     (write_data_i[InDWidth:1]),
        .data_o                     (data_cache1)
    );
    SCRATCH_PAD_SRAM #(.Depth(SramDepth), .DWidth(InDWidth)) SCRATCH_PAD_1(
        .clk_i                      (clk_i),
        .csb_i                      (!request && (addr_i[Index+1:Index] == 'd1)),
        .web_i                      (!write_i),
        .addr_i                     (addr_i[Index-1:2]),
        .oeb_i                      (!oen),
        .data_i                     (write_data_i[InDWidth:1]),
        .data_o                     (data_cache1)
    );
    SCRATCH_PAD_SRAM #(.Depth(SramDepth), .DWidth(InDWidth)) SCRATCH_PAD_2(
        .clk_i                      (clk_i),
        .csb_i                      (!request && (addr_i[Index+1:Index] == 'd2)),
        .web_i                      (!write_i),
        .addr_i                     (addr_i[Index-1:2]),
        .oeb_i                      (!oen),
        .data_i                     (write_data_i[InDWidth:1]),
        .data_o                     (data_cache2)
    );
    SCRATCH_PAD_SRAM #(.Depth(SramDepth), .DWidth(InDWidth)) SCRATCH_PAD_3(
        .clk_i                      (clk_i),
        .csb_i                      (!request && (addr_i[Index+1:Index] == 'd3)),
        .web_i                      (!write_i),
        .addr_i                     (addr_i[Index-1:2]),
        .oeb_i                      (!oen),
        .data_i                     (write_data_i[InDWidth:1]),
        .data_o                     (data_cache3)
    );
`endif

////////////////////////////////////////////////////////////////////////////////

endmodule
