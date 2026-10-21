################################################################################
## AS501
## Final Project
## Placement & Opimization
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

set PREVIOUS_STEP $INIT_DESIGN_BLOCK_LABEL
set CURRENT_STEP $PLACE_OPT_BLOCK_LABEL

open_lib $DESIGN_LIBRARY
copy_block -from ${DESIGN_NAME}/${PREVIOUS_STEP} -to ${DESIGN_NAME}/${CURRENT_STEP}
current_block ${DESIGN_NAME}/${CURRENT_STEP}

##########################################################################
## Pre-Placement check
##########################################################################
report_ideal_network -scenarios [all_scenarios]
report_ignored_layers
report_utilization
report_net_fanout -high_fanout

##########################################################################
## Pre-Placement setup
##########################################################################
# CTS cell and NDR should be set for accurate estimation
# Cell used for CTS
set_dont_touch [get_lib_cells $CTS_CELLS] false
suppress_message ATTR-12
set_lib_cell_purpose -exclude cts [get_lib_cells]
set_lib_cell_purpose -include cts [get_lib_cells $CTS_CELLS]
# CTS NDR setup
source -echo $TCL_CTS_NDR

# Enable TIE-cells
set_dont_touch [get_lib_cells $TIE_CELLS] false
set_lib_cell_purpose -include optimization [get_lib_cells $TIE_CELLS]
# Limit the fanout of each tie cell to 8
set_app_options -name opt.tie_cell.max_fanout -value 8

##########################################################################
## Placement QoR(Quality of Result) setup
##########################################################################
# # Congestion-focused setup
set_app_options -name place_opt.place.congestion_effort -value high
set_app_options -name place_opt.initial_drc.global_route_based -value true

##########################################################################
## Placement!
##########################################################################
place_opt

##########################################################################
## Post-Placement check
##########################################################################
check_legality
check_mv_design

save_block

# Reports
report_congestion -rerun_global_router
report_qor -summary
report_power
report_timing

exit