################################################################################
## AS501
## Final Project
## Post-Routing Optimization
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

set PREVIOUS_STEP $ROUTE_AUTO_BLOCK_LABEL
set CURRENT_STEP $ROUTE_OPT_BLOCK_LABEL

open_lib $DESIGN_LIBRARY
copy_block -from ${DESIGN_NAME}/${PREVIOUS_STEP} -to ${DESIGN_NAME}/${CURRENT_STEP}
current_block ${DESIGN_NAME}/${CURRENT_STEP}

##########################################################################
## Post-Routing Optimization setup
##########################################################################
# PrimeTime timing analysis setup
set_app_options -name time.enable_ccs_rcv_cap -value true
set_app_options -name time.delay_calc_waveform_analysis_mode -value full_design

##########################################################################
## Post-Routing Optimization!
##########################################################################
route_opt

# Check DRCs
check_routes
# Check LVS
check_lvs -checks all

save_block

# Report final QoR!
redirect -tee -file ${REPORT_DIR}/${ROUTE_OPT_BLOCK_LABEL}.report_qor.log {report_qor -summary}
redirect -tee -file ${REPORT_DIR}/${ROUTE_OPT_BLOCK_LABEL}.report_timing.log {report_timing}
redirect -tee -file ${REPORT_DIR}/${ROUTE_OPT_BLOCK_LABEL}.report_power.log {report_power}

exit
