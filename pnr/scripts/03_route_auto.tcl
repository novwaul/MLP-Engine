################################################################################
## AS501
## Final Project
## Routing
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

set PREVIOUS_STEP $CLOCK_OPT_BLOCK_LABEL
set CURRENT_STEP $ROUTE_AUTO_BLOCK_LABEL

open_lib $DESIGN_LIBRARY
copy_block -from ${DESIGN_NAME}/${PREVIOUS_STEP} -to ${DESIGN_NAME}/${CURRENT_STEP}
current_block ${DESIGN_NAME}/${CURRENT_STEP}

##########################################################################
## Pre-Routing check
##########################################################################
report_qor -summary
check_routability

##########################################################################
## Pre-Routing setup
##########################################################################
# Antenna rule
source -echo $ANTENNA_RULE

# Timing-driven routing
set_app_options -name route.global.timing_driven -value true
set_app_options -name route.track.timing_driven  -value true
set_app_options -name route.detail.timing_driven -value true

# Crosstalk prevention setup
set_app_options -name route.global.crosstalk_driven -value false
set_app_options -name route.track.crosstalk_driven  -value true

##########################################################################
## Routing!
##########################################################################
route_auto

##########################################################################
## Post-Routing check
##########################################################################
# Check DRCs
check_routes
# Check LVS
check_lvs -checks all -max_errors 100

save_block

exit