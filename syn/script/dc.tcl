#!/bin/bash
################################################################################
## AS501
## Final Project
## DC Synthesis Script
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
    # Setup number of cores
    set_host_options -max_cores 8

    # Setup library
    set_app_var search_path "$LIB_DIR $search_path"
    set_app_var target_library "$TARGET_DB_FILES $TARGET_MEM_DB_FILES"
    set_app_var synthetic_library dw_foundation.sldb
    set_app_var link_library "* $target_library $synthetic_library"
    # Enable inference of multibit registers from the buses
    set_app_var hdlin_infer_multibit default_all

    # Remove new variable info messages from the end of the log file
    set_app_var sh_new_variable_message false

    # Define the verification setup file for Formality
    set_svf $OUT_DIR/$TOP_NAME.mapped.svf

    # Make work directory which contains *.pvl, *.syn, *.mr
    define_design_lib work -path $OUT_DIR/work

    # Read RTL source files
    analyze -format sverilog -define $DEFINE_LIST $RTL_LIST

    # Elaborate & Link
    elaborate $TOP_NAME
    link

    # Set wire names to lower case
    define_name_rules LOWER_CASE -type net -allowed "a-z 0-9_*"
    change_names -rules verilog -hierarchy
    change_names -rules LOWER_CASE -hierarchy

    # Prevent assignment statements in the Verilog netlist
    set_fix_multiple_port_nets -all -buffer_constants

    # Check the current design for consistency
    redirect -tee -file $RPT_DIR/1_check_design.rpt {check_design}

    # In/out port constraints
    # Remove all user-defined attributes from the current design
    reset_design

    # Set operating condition
    set_operating_conditions tt1p05v25c

    # Create clock
    create_clock -period $CLOCK_PERIOD [get_ports $TOP_CLK]

    # Set clock skew + jitter + setup margin
    set_clock_uncertainty -setup [expr 0.07 * $CLOCK_PERIOD] [get_clocks $TOP_CLK]

    # Set clock transition (How long it takes to be recognized as 0 to 1)
    set_clock_transition [expr 0.016 * $CLOCK_PERIOD] [get_clocks $TOP_CLK]

    # Assume the core is connected to SRAM
    # Set input delay (Assume ta = 0.6)
    set INPUTS_EX_GLOBAL [remove_from_collection [all_inputs] [get_ports "$TOP_CLK $TOP_RST"]]
    set_input_delay -max 0.6 -clock $TOP_CLK $INPUTS_EX_GLOBAL
    # Set output delay (Assume tas, tcss, twes, tds = 1.0)
    set_output_delay -max 1.0 -clock $TOP_CLK [all_outputs]

    # Report clock
    redirect -tee -file $RPT_DIR/2_check_clock.rpt {report_clock}

    # Compile the Design
    redirect -tee -file $RPT_DIR/3_compile.rpt {eval "compile_ultra -no_autoungroup"}

    # Write Out Final Design and Reports
    # .ddc: Recommended binary format used for subsequent Design Compiler sessions
    # .v  : Verilog netlist for ASCII flow (Formality, PrimeTime, VCS)
    # .sdf: SDF backannotated topographical mode timing for PrimeTime
    # .sdc: SDC constraints for ASCII flow
    write_file -format ddc -hierarchy -output $OUT_DIR/$TOP_NAME.mapped.ddc
    set_app_var verilogout_no_tri true
    change_names -rules verilog -hierarchy
    write_file -format verilog -hierarchy -output $OUT_DIR/$TOP_NAME.mapped.v
    write_sdf $OUT_DIR/$TOP_NAME.mapped.sdf
    write_sdc $OUT_DIR/$TOP_NAME.mapped.sdc

    # Write and close SVF file and make it available for immediate use
    set_svf -off

    # Generate Final Reports
    redirect -tee -file $RPT_DIR/4_report_timing.rpt {report_timing -transition_time -nets -attributes -nosplit}
    redirect -tee -file $RPT_DIR/5_report_area.rpt {report_area -physical -hierarchy -nosplit}
    redirect -tee -file $RPT_DIR/6_report_power.rpt {report_power -nosplit}

    # gui_start
    exit
##
################################################################################