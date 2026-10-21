################################################################################
## AS501
## Final Project
## Write out Verilog netlist & GDS
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

set PREVIOUS_STEP $SIGN_OFF_BLOCK_LABEL
set CURRENT_STEP $WRITE_DATA_BLOCK_LABEL

open_lib $DESIGN_LIBRARY
copy_block -from ${DESIGN_NAME}/${PREVIOUS_STEP} -to ${DESIGN_NAME}/${CURRENT_STEP}
current_block ${DESIGN_NAME}/${CURRENT_STEP}

########################################################################
## Change Names
########################################################################
## change the names of ports, cells, and nets in a design for output netlist,
redirect -tee -file ${REPORT_DIR}/${WRITE_DATA_BLOCK_LABEL}.report_names.log {report_names -rules verilog}

change_names -rules verilog -hierarchy

save_block

########################################################################
## Write Verilog
########################################################################
# without P/G
write_verilog ${OUTPUT_DIR}/${DESIGN_NAME}.v \
    -exclude {scalar_wire_declarations leaf_module_declarations pg_objects end_cap_cells well_tap_cells filler_cells pad_spacer_cells physical_only_cells cover_cells} \
    -hierarchy all

# with P/G
write_verilog ${OUTPUT_DIR}/${DESIGN_NAME}.pg.v \
    -exclude {scalar_wire_declarations leaf_module_declarations end_cap_cells well_tap_cells filler_cells pad_spacer_cells physical_only_cells cover_cells supply_statements} \
    -hierarchy all

###########################################################################
## Write GDS
###########################################################################
write_gds ${OUTPUT_DIR}/${DESIGN_NAME}.gds -hierarchy all -long_names -keep_data_type

###########################################################################
## Write SDF
###########################################################################

write_sdf ${OUTPUT_DIR}/${DESIGN_NAME}.sdf

save_block
save_lib

exit
