################################################################################
## AS501
## Final Project
## Sign off
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

set PREVIOUS_STEP $ROUTE_OPT_BLOCK_LABEL
set CURRENT_STEP $SIGN_OFF_BLOCK_LABEL

open_lib $DESIGN_LIBRARY
copy_block -from ${DESIGN_NAME}/${PREVIOUS_STEP} -to ${DESIGN_NAME}/${CURRENT_STEP}
current_block ${DESIGN_NAME}/${CURRENT_STEP}

###########################################################################
## Filler cell insertion
##########################################################################
create_stdcell_fillers -lib_cells $FILLER_CELLS -rules {post_route_auto_delete}
connect_pg_net

remove_stdcell_fillers_with_violation

save_block

###########################################################################
## ICV In-Design DRC
##########################################################################
# Save block before invoking ICV - ICV works on saved data
set_app_options -name signoff.check_drc.runset              -value $ICV_DRC_RULE_FILE
set_app_options -name signoff.check_drc.max_errors_per_rule -value 1000
set_app_options -name signoff.check_drc.run_dir             -value "${OUTPUT_DIR}/ICV_DRC_run"

# Run DRC
# Check only metal layers
signoff_check_drc -select_rules { "M2*" "M3*" "M4*" "M5*" "M6*" "M7*" "M8*" "M9*" }

# Fix DRC Violations after Run DRC
set_app_options -name signoff.fix_drc.init_drc_error_db -value "${OUTPUT_DIR}/ICV_DRC_run"
signoff_fix_drc -select_rules { "M2*" "M3*" "M4*" "M5*" "M6*" "M7*" "M8*" "M9*" }

save_block

exit