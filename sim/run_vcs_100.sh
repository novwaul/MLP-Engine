#!/bin/bash
################################################################################
## AS501
## Final Project
## Run VCS Simulation Script
################################################################################
## Copyright (c) 2024 by Smart Energy-Efficient Design Lab. (SEED), KAIST
## All rights reserved.
##
##                            Written by Hyungjoon Bae (jo_on@kaist.ac.kr)
##                            Supervised by Wanyeong Jung (wanyeong@kaist.ac.kr)
################################################################################

################################################################################
## Don't touch
##
    THIS_SCRIPT_DIR="$(realpath "$(dirname "$BASH_SOURCE")")"
    RTL_DIR="$THIS_SCRIPT_DIR/../rtl"
    TB_DIR="$THIS_SCRIPT_DIR/tb"
    OUT_DIR="./out"

    if [ -n "$OUT_DIR" ]; then
        if [ -d "$OUT_DIR" ]; then
            # Clean the output directory
            rm -rf $OUT_DIR/*
        else
            # Make an output directory
            mkdir -p $OUT_DIR
        fi
    else
        echo "set OUT_DIR variable"
    fi

    # Make log file
    cd $OUT_DIR
    TIME=$(date +%Y-%m-%d_%H:%M)
    touch $TIME.txt
##
################################################################################

################################################################################
## Modify to fit your source file names
##
    # Simulated rtl list
    RTL_LIST="$TB_DIR/core_tb_100.sv                            \
              $RTL_DIR/common/core_package.sv                    \
              $RTL_DIR/common/d_flip_flop.sv                     \
              $RTL_DIR/common/mux2to1.sv                         \
              $RTL_DIR/common/mux3to1.sv                         \
              $RTL_DIR/common/mux4to1.sv                         \
              $RTL_DIR/common/mux5to1.sv                         \
              $RTL_DIR/common/counter.sv                         \
              $RTL_DIR/memory/memory_top.sv                      \
              /technology/SAED32/lib/sram/verilog/saed32sram.v   \
              $RTL_DIR/cache/submodule/cache_sram.sv             \
              $RTL_DIR/cache/instr_cache.sv                      \
              $RTL_DIR/scratch_pad/submodule/scratch_pad_sram.sv \
              $RTL_DIR/scratch_pad/scratch_pad.sv                \
              $RTL_DIR/scalar_core/alu.sv                        \
              $RTL_DIR/scalar_core/csr.sv                        \
              $RTL_DIR/scalar_core/decoder.sv                    \
              $RTL_DIR/scalar_core/regfile.sv                    \
              $RTL_DIR/scalar_core/systolic_array.sv             \
              $RTL_DIR/scalar_core/scalar_core.sv                \
              $RTL_DIR/cpu_top.sv"

    # Timescale
    TIMESCALE="1ns/1ps"
##
################################################################################

################################################################################
## Modify as needed
##
    # Run vcs
    vcs -fgp                    \
        -full64                 \
        -sverilog $RTL_LIST     \
        -timescale=$TIMESCALE   \
        +incdir+$DC/dw/sim_ver  \
        +define+SIM             \
        -debug_access+all       \
        -kdb                    \
        -l vcs.log
    ./simv -fgp=num_threads:1 -fgp=num_fsdb_threads:1 -fgp=fsdb_adjust_cores | tee vcs_sim.log
##
################################################################################
