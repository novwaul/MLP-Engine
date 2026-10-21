////////////////////////////////////////////////////////////////////////////////
// AS501
// Final Project
// Scalar Core Testbench
////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024 by Smart Energy-Efficient Design Lab. (SEED), KAIST
// All rights reserved.
//
//                            Written by Hyungjoon Bae (jo_on@kaist.ac.kr)
//                            Supervised by Wanyeong Jung (wanyeong@kaist.ac.kr)
////////////////////////////////////////////////////////////////////////////////

module CORE_TB();
    localparam DWidth        = 32;
    localparam InitFile      = "../../program/out/mlp_10000.hex";
    localparam MemDepth      = 32'h02004000;
    localparam IMemStart     = 32'h00000000;
    localparam DMemStart     = 32'h00004000;

    localparam InputSize     = 'd784;
    localparam Hidden1Size   = 'd128;
    localparam Hidden2Size   = 'd64;
    localparam OutputSize    = 'd10;
    localparam NumOfTest     = 'd10000;
    localparam ArraySize     = 'd4;

    localparam Fc1OAddr      = DMemStart;
    localparam Fc2OAddr      = DMemStart;
    localparam Fc1WAddr      = DMemStart   + 32'h00001000;
    localparam Fc2WAddr      = (Fc1WAddr   + InputSize   * Hidden1Size * 4);
    localparam Fc3WAddr      = (Fc2WAddr   + Hidden1Size * Hidden2Size * 4);
    localparam Fc1BAddr      = (Fc3WAddr   + Hidden2Size * OutputSize  * 4);
    localparam Fc2BAddr      = (Fc1BAddr   + Hidden1Size * 4);
    localparam Fc3BAddr      = (Fc2BAddr   + Hidden2Size * 4);
    localparam OutputAddr    = (Fc3BAddr   + OutputSize  * 4);
    localparam InputAddr     = (OutputAddr + ArraySize   * ArraySize   * ((OutputSize+ArraySize-1)/ArraySize) * 4);
    localparam LabelAddr     = (InputAddr  + InputSize   * NumOfTest   * 4);

    localparam ImageInitFile = "../../program/test_code/image/image_10000.txt";
    localparam Fc1WInitFile  = "../../program/test_code/parameter/fc1_weight.txt";
    localparam Fc1BInitFile  = "../../program/test_code/parameter/fc1_bias.txt";
    localparam Fc2WInitFile  = "../../program/test_code/parameter/fc2_weight.txt";
    localparam Fc2BInitFile  = "../../program/test_code/parameter/fc2_bias.txt";
    localparam Fc3WInitFile  = "../../program/test_code/parameter/fc3_weight.txt";
    localparam Fc3BInitFile  = "../../program/test_code/parameter/fc3_bias.txt";
    localparam LabelInitFile = "../../program/test_code/label/label.txt";

    logic                           clk;
    logic                           mclk;
    logic                           rst_n;
    logic                           imem_req;
    logic   [DWidth-1:0]            imem_rdata;
    logic                           imem_ready;

    logic                           dmem_req;
    logic   [DWidth-1:0]            dmem_rdata;
    logic   [DWidth-1:0]            dmem_wdata;
    logic   [DWidth-1:0]            dmem_addr;
    logic                           dmem_ready;
    logic                           dmem_write;

    logic   [DWidth-1:0]            imem_addr;
    logic   [DWidth-1:0]            imem_addr_corr;

    int                             i;
    integer                         fd;
    integer                         result;

    // Clock generator
    // You can modify ClkPeriod according to your hardware
    localparam ClkPeriod     = 10.0;
    localparam ClkHalf       = ClkPeriod / 2;
    initial begin
        clk = 1'b0;
        forever #ClkHalf clk = ~clk;
    end

    // Memory Clock generator
    // You can't modify mClkPeriod
    localparam mClkPeriod    = 10.0;
    localparam mClkHalf      = mClkPeriod / 2;
    initial begin
        mclk = 1'b0;
        forever #mClkHalf mclk = ~mclk;
    end

    // Instance
    CPU_TOP #(.DWidth(DWidth)) DUT(
        .clk_i                      (clk),
        .rst_ni                     (rst_n),

        .imem_ready_i               (imem_ready),
        .imem_rdata_i               (imem_rdata),
        .imem_addr_o                (imem_addr),
        .imem_req_o                 (imem_req),

        .dmem_ready_i               (dmem_ready),
        .dmem_rdata_i               (dmem_rdata),
        .dmem_wdata_o               (dmem_wdata),
        .dmem_addr_o                (dmem_addr),
        .dmem_req_o                 (dmem_req),
        .dmem_write_o               (dmem_write)
    );

    MEMORY_TOP #(.DWidth(DWidth), .MemDepth(MemDepth),
                 .InitFile(InitFile), .IMemStart(IMemStart),
                 .DMemStart(DMemStart), .InputAddr(InputAddr),
                 .Fc1WAddr(Fc1WAddr), .Fc1BAddr(Fc1BAddr),
                 .Fc2WAddr(Fc2WAddr), .Fc2BAddr(Fc2BAddr),
                 .Fc3WAddr(Fc3WAddr), .Fc3BAddr(Fc3BAddr),
                 .LabelAddr(LabelAddr), .ImageInitFile(ImageInitFile),
                 .Fc1WInitFile(Fc1WInitFile), .Fc1BInitFile(Fc1BInitFile),
                 .Fc2WInitFile(Fc2WInitFile), .Fc2BInitFile(Fc2BInitFile),
                 .Fc3WInitFile(Fc3WInitFile), .Fc3BInitFile(Fc3BInitFile),
                 .LabelInitFile(LabelInitFile)) MEMORY(
        .clk_i                      (clk),
        .mclk_i                     (mclk),
        .rst_ni                     (rst_n),

        .imem_req_i                 (imem_req),
        .imem_write_i               (),
        .imem_addr_i                (imem_addr),
        .imem_wdata_i               (),
        .imem_ready_o               (imem_ready),
        .imem_rdata_o               (imem_rdata),

        .dmem_req_i                 (dmem_req),
        .dmem_write_i               (dmem_write),
        .dmem_addr_i                (dmem_addr),
        .dmem_wdata_i               (dmem_wdata),
        .dmem_ready_o               (dmem_ready),
        .dmem_rdata_o               (dmem_rdata)
    );

    // Exit Flag
    int exit_signal = 0;

    always @(*) begin
        if (DUT.SCORE.SRF.GPR[25] == 'd99999) begin
            exit_signal = 1;
        end
    end

    always @(DUT.SCORE.SRF.GPR[26]) begin
        if (DUT.SCORE.SRF.GPR[26] != 0) begin
            $display("Current correction count = %-d", DUT.SCORE.SRF.GPR[27]);
        end
        if (DUT.SCORE.SRF.GPR[26] < NumOfTest) begin
            $display("Inference image #%-d ", DUT.SCORE.SRF.GPR[26] + 1);
        end
    end

    real accuracy;

    // Test Scenario
    initial begin
        i = 0;
        rst_n = 1'b1;
        #mClkPeriod;
        rst_n = 1'b0;
        #mClkPeriod;
        rst_n = 1'b1;
        forever begin
            @(posedge clk)
            if (exit_signal == 1) begin
                accuracy = DUT.SCORE.SRF.GPR[27];
                accuracy = accuracy / NumOfTest * 100;
                $display("-------------------------------------------------------");
                $display("Accuracy = %-.2f", accuracy);
                $display("-------------------------------------------------------");
                $display("mcycleh = %08X, mcycle = %08X", DUT.SCORE.SRF.GPR[29], DUT.SCORE.SRF.GPR[28]);
                $display("minstreth = %08X, minstret = %08X", DUT.SCORE.SRF.GPR[31], DUT.SCORE.SRF.GPR[30]);
                $display("-------------------------------------------------------");
                $finish();
            end
        end
        $finish();
    end

    // Waveform dump
    // initial begin
    //     $fsdbDumpfile("./core.fsdb");
    //     $fsdbDumpvars("+mda", DUT);
    // end

endmodule