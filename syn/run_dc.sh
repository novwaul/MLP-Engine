#!/bin/bash
################################################################################
## AS501
## Final Project
## Run DC Synthesis Script
################################################################################
## Copyright (c) 2024 by Smart Energy-Efficient Design Lab. (SEED), KAIST
## All rights reserved.
##
##                            Written by Hyungjoon Bae (jo_on@kaist.ac.kr)
##                                       Michal Gorywoda (hotwater@kaist.ac.kr)
##                            Supervised by Wanyeong Jung (wanyeong@kaist.ac.kr)
################################################################################

################################################################################
## Don't touch
##
    THIS_SCRIPT_DIR="$(realpath "$(dirname "$BASH_SOURCE")")"
    RTL_DIR="$THIS_SCRIPT_DIR/../rtl"

    # Library path & list
    LIB_DIR="/technology/SAED32/lib"
    TARGET_DB_FILES="$LIB_DIR/stdcell_rvt/db_nldm/saed32rvt_tt1p05v25c.db"
    TARGET_MEM_DB_FILES="$LIB_DIR/sram/db_nldm/saed32sram_tt1p05v25c.db"

    # Top module
    TOP_NAME="CPU_TOP"

    TOP_CLK="clk_i"
    TOP_RST="rst_ni"
##
################################################################################

################################################################################
## Modify as needed
##
    # Synthesized rtl list
    RTL_LIST=("$RTL_DIR/common/core_package.sv        \
               $RTL_DIR/common/d_flip_flop.sv         \
               $RTL_DIR/common/mux2to1.sv             \
               $RTL_DIR/common/mux3to1.sv             \
               $RTL_DIR/common/mux4to1.sv             \
               $RTL_DIR/common/mux5to1.sv             \
               $RTL_DIR/common/counter.sv             \
               $RTL_DIR/cache/submodule/cache_sram.sv \
               $RTL_DIR/cache/instr_cache.sv          \
               $RTL_DIR/scratch_pad/submodule/scratch_pad_sram.sv \
               $RTL_DIR/scratch_pad/scratch_pad.sv                \
               $RTL_DIR/scalar_core/alu.sv            \
               $RTL_DIR/scalar_core/csr.sv            \
               $RTL_DIR/scalar_core/decoder.sv        \
               $RTL_DIR/scalar_core/regfile.sv        \
               $RTL_DIR/scalar_core/systolic_array.sv \
               $RTL_DIR/scalar_core/scalar_core.sv    \
               $RTL_DIR/cpu_top.sv")

    # Clock period in ns
    CLOCK_PERIOD="11.0"

    # Define list
    DEFINE_LIST=("")
##
################################################################################

################################################################################
## Don't touch
##
    OUT_DIR=$THIS_SCRIPT_DIR/out
    RPT_DIR=$OUT_DIR/rpt

    if [ -n "$OUT_DIR" ]; then
        if [ -d "$OUT_DIR" ]; then
            # Clean the output directory
            rm -rf $OUT_DIR/*
            mkdir -p $RPT_DIR
        else
            # Make an output and report directory
            mkdir -p $OUT_DIR
            mkdir -p $RPT_DIR
        fi
    else
        echo "set OUT_DIR variable"
    fi

    # Run DC
    dc_shell -f ./script/dc.tcl                                \
             -x "set LIB_DIR $LIB_DIR;                         \
                 set TARGET_DB_FILES $TARGET_DB_FILES;         \
                 set TARGET_MEM_DB_FILES $TARGET_MEM_DB_FILES; \
                 set RTL_LIST [list $RTL_LIST];                \
                 set DEFINE_LIST [list $DEFINE_LIST];          \
                 set OUT_DIR $OUT_DIR;                         \
                 set RPT_DIR $RPT_DIR;                         \
                 set TOP_NAME $TOP_NAME;                       \
                 set CLOCK_PERIOD $CLOCK_PERIOD;               \
                 set TOP_CLK $TOP_CLK;                         \
                 set TOP_RST $TOP_RST;"                        \
             -output_log_file $OUT_DIR/dc_$CLOCK_PERIOD.log

    # Make time log file
    TIME=$(date +"%Y-%m-%d_%H:%M")
    echo $TIME >> $OUT_DIR/$TIME.txt

    # Clean dirty files
    rm -rf *.mr *.pvl *.syn *.svf
    rm -rf command.log
    rm -rf dc*.log
    rm -rf filenames*.log
    rm -rf alib-52

    cd $OUT_DIR
    SDC_FILE="$TOP_NAME.mapped.sdc"

    if [ ! -f "$SDC_FILE" ]; then
        exit 1
    fi

    TMP_SDC_FILE=$(mktemp)

    while IFS= read -r line; do
        modified_line=$(echo "$line" | sed 's/set_operating_conditions/# set_operating_conditions/g')
        echo "$modified_line" >> "$TMP_SDC_FILE"
    done < "$SDC_FILE"
    mv "$TMP_SDC_FILE" "$SDC_FILE"
    rm -rf $TMP_SDC_FILE

    cd $THIS_SCRIPT_DIR
##
################################################################################