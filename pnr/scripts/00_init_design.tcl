################################################################################
## AS501
## Final Project
## Initialize design (Design setup & floorplan)
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

##################################
## Create the design library
## Load the netlist
##################################
create_lib $DESIGN_LIBRARY -technology $TECH_FILE -ref_libs $NDM_LIST

# Load netlist
read_verilog -top $DESIGN_NAME $VERILOG_NETLIST_FILE
current_block $DESIGN_NAME

link_block

##################################
## RC parasitics, Placement site
## and Routing layer setup
##################################
read_parasitic_tech -layermap $LAYER_MAP_FILE($PARASITIC_WORST) -tlup $TLUPLUS_FILE($PARASITIC_WORST) -name $PARASITIC_WORST
read_parasitic_tech -layermap $LAYER_MAP_FILE($PARASITIC_BEST) -tlup $TLUPLUS_FILE($PARASITIC_BEST) -name $PARASITIC_BEST

set_attribute [get_site_defs $SITE_DEFAULT] symmetry $SITE_SYMMETRY
set_attribute [get_site_defs $SITE_DEFAULT] is_default true

set_attribute [get_layers $HORIZONTAL_ROUTING_LAYER_LIST] routing_direction horizontal
set_attribute [get_layers $VERTICAL_ROUTING_LAYER_LIST] routing_direction vertical
set_ignored_layers -min_routing_layer $MIN_ROUTING_LAYER
set_ignored_layers -max_routing_layer $MAX_ROUTING_LAYER

##################################
## Load UPF, Floorplan
##################################
load_upf $UPF_FILE
commit_upf
connect_pg_net

source -echo $TCL_FLOORPLAN

check_mv_design

##################################
## Timing and Design Constraints
##################################
# MCMM setup
source -echo $TCL_MCMM_SETUP

# If there are propagated clocks, remove them
foreach_in_collection mode [all_modes] {
	current_mode $mode
	remove_propagated_clocks [all_clocks]
	remove_propagated_clocks [get_ports]
	remove_propagated_clocks [get_pins -hierarchical]
}

# report_xx commands apply to the current scenario
current_scenario func_ss0p95v125c

report_scenario
report_pvt

##################################
## Save the block
##################################
rename_block -to_block $DESIGN_NAME/$INIT_DESIGN_BLOCK_LABEL
save_block

exit