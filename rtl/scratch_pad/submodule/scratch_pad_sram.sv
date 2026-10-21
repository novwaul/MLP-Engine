
module SCRATCH_PAD_SRAM #(
    parameter DWidth = 8,
    parameter Depth  = 1024,
    localparam Index = $clog2(Depth)
)(
    input   logic                   clk_i,
    input   logic                   csb_i,
    input   logic                   oeb_i,
    input   logic                   web_i,
    input   logic   [Index-1:0]     addr_i,
    input   logic   [DWidth-1:0]    data_i,
    output  logic   [DWidth-1:0]    data_o
);

    SRAM1RW1024x8 SRAM1024_8(
        .CE                         (clk_i),
        .CSB                        (csb_i),
        .WEB                        (web_i),
        .OEB                        (oeb_i),
        .A                          (addr_i),
        .I                          (data_i[DWidth-1:0]),
        .O                          (data_o[DWidth-1:0])
    );

endmodule