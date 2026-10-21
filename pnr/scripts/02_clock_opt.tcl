################################################################################
## AS501
## Final Project
## CTS & Opimization
################################################################################
## Copyright (c) 2024 by Smart Energy-Efficient Design Lab. (SEED), KAIST
## All rights reserved.
##
##                            Written by Jihwan Cho (jihwancho@kaist.ac.kr)
##                            Supervised by Wanyeong Jung (wanyeong@kaist.ac.kr)
################################################################################

################################################################################
## Don't touch
source -echo ./setup/icc2_common_setup.tcl

set PREVIOUS_STEP $PLACE_OPT_BLOCK_LABEL
set CURRENT_STEP $CLOCK_OPT_BLOCK_LABEL

open_lib $DESIGN_LIBRARY
copy_block -from ${DESIGN_NAME}/${PREVIOUS_STEP} -to ${DESIGN_NAME}/${CURRENT_STEP}
current_block ${DESIGN_NAME}/${CURRENT_STEP}

##########################################################################
## Pre-CTS check
##########################################################################
report_qor -summary
check_clock_trees

##########################################################################
## Pre-CTS setup
##########################################################################
# Timing & DRC setup
set_max_transition 0.2 -clock_path [get_clocks] -corners [all_corners]
set_max_capacitance 0.1 -clock_path [get_clocks] -corners [all_corners]

set_clock_uncertainty 0.1 -setup [get_clocks] -corners [all_corners]
set_clock_uncertainty 0.05 -hold [get_clocks] -corners [all_corners]

##########################################################################
## Pre-CTS setup
##########################################################################
set_app_options -name time.remove_clock_reconvergence_pessimism -value true
set_app_options -name cts.compile.enable_global_route -value true

##########################################################################
## CTS!
##########################################################################
set_app_options -name clock_opt.flow.enable_ccd -value false

clock_opt -to route_clock

save_block

##########################################################################
## Post-CTS check
##########################################################################
report_qor -summary

report_timing -from [get_clocks clk_i]

exit