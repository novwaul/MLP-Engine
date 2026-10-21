################################################################################
## AS501
## Final Project
## Floorplan
################################################################################
## Copyright (c) 2024 by Smart Energy-Efficient Design Lab. (SEED), KAIST
## All rights reserved.
##
##                            Written by Jihwan Cho (jihwancho@kaist.ac.kr)
##                            Supervised by Wanyeong Jung (wanyeong@kaist.ac.kr)
################################################################################

################################################################################
## Don't touch

# Floorplan Initialization : Core area
set CORE_WIDTH 300
set CORE_HEIGHT 300
set CORE_OFFSET 20

initialize_floorplan -side_length [list $CORE_WIDTH $CORE_HEIGHT] -core_offset $CORE_OFFSET

# Place Hard macros
set CORE_REGION [get_attribute [get_core_area] -name bbox]

set SRAM48_WIDTH [get_attribute ICACHE/ICACHE_SRAM/SRAM48 -name width]
set SRAM48_HEIGHT [get_attribute ICACHE/ICACHE_SRAM/SRAM48 -name height]
set SRAM48_LOCATION [list [expr [lindex $CORE_REGION 1 0] - $SRAM48_HEIGHT] [expr [lindex $CORE_REGION 1 1] - $SRAM48_WIDTH]]

set SRAM8_WIDTH [get_attribute ICACHE/ICACHE_SRAM/SRAM8 -name width]
set SRAM8_HEIGHT [get_attribute ICACHE/ICACHE_SRAM/SRAM8 -name height]
set SRAM8_LOCATION [list [expr [lindex $CORE_REGION 1 0] - $SRAM8_HEIGHT] [expr [lindex $SRAM48_LOCATION 1] - $SRAM8_WIDTH - 10]]

move_objects [get_cell ICACHE/ICACHE_SRAM/SRAM48] -to $SRAM48_LOCATION -rotate R270
move_objects [get_cell ICACHE/ICACHE_SRAM/SRAM8] -to $SRAM8_LOCATION -rotate MXR90

# Create Macro Keepout Margin
set SRAM48_KEEPOUT {5 5 0 0}
set SRAM8_KEEPOUT [list [expr 5 - ($SRAM8_HEIGHT - $SRAM48_HEIGHT)] 4 0 5]

create_keepout_margin -type hard -outer $SRAM48_KEEPOUT {ICACHE/ICACHE_SRAM/SRAM48}
create_keepout_margin -type hard -outer $SRAM8_KEEPOUT {ICACHE/ICACHE_SRAM/SRAM8}

# Apply Power Routing Blockages (added to fix DRC violtaions)
set SRAM48_PG_RB_REGION [get_attribute {ICACHE/ICACHE_SRAM/SRAM48} -name boundary_bbox]
set SRAM8_PG_RB_REGION [get_attribute {ICACHE/ICACHE_SRAM/SRAM8} -name boundary_bbox]

create_routing_blockage -name SRAM48_RB -layers {M6} -boundary $SRAM48_PG_RB_REGION -zero_spacing
create_routing_blockage -name SRAM8_RB -layers {M6} -boundary $SRAM8_PG_RB_REGION -zero_spacing

# Place I/O pins
set_block_pin_constraints -self -allowed_layers {M3 M4 M5 M6}

create_pin_guide -exclusive -boundary {{-0.5 100} {0.5 340}} -name imem_ports -pin_spacing 10 [get_ports {imem*}]
create_pin_guide -exclusive -boundary {{0 -0.5} {340 0.5}} -name dmem_ports -pin_spacing 10 [get_ports {dmem*}]
create_pin_guide -exclusive -boundary {{-0.5 20} {0.5 30}} -name sync_ports -pin_spacing 10 [get_ports {clk_i rst_ni}]

place_pins -self

# Fix the hard macros location
set_fixed_objects [get_flat_cells -filter "is_hard_macro"]

# Build Power network (Power Network Synthesis)
source -echo $TCL_PNS

# Verity Power Network
check_pg_missing_vias
check_pg_drc -ignore_std_cells
check_pg_connectivity -check_std_cell_pins none

# Apply Routing Blockages
set SRAM48_RB_REGION [get_attribute {ICACHE/ICACHE_SRAM/SRAM48} -name boundary_bbox]
set SRAM48_RB_REGION [lreplace $SRAM48_RB_REGION 0 0 [list [expr [lindex $SRAM48_RB_REGION 0 0] + 0.25] [expr [lindex $SRAM48_RB_REGION 0 1] + 0.25]]]
set SRAM48_RB_REGION [lreplace $SRAM48_RB_REGION 1 1 [list [expr [lindex $SRAM48_RB_REGION 1 0] - 0.0] [expr [lindex $SRAM48_RB_REGION 1 1] - 0.0]]]

set SRAM8_RB_REGION [get_attribute {ICACHE/ICACHE_SRAM/SRAM8} -name boundary_bbox]
set SRAM8_RB_REGION [lreplace $SRAM8_RB_REGION 0 0 [list [expr [lindex $SRAM8_RB_REGION 0 0] + 0.25] [expr [lindex $SRAM8_RB_REGION 0 1] + 0.0]]]
set SRAM8_RB_REGION [lreplace $SRAM8_RB_REGION 1 1 [list [expr [lindex $SRAM8_RB_REGION 1 0] - 0.0] [expr [lindex $SRAM8_RB_REGION 1 1] - 0.25]]]

# create_routing_blockage -name SRAM48_RB -layers {M1 M2 M3 M4 M5 M6} -boundary $SRAM48_RB_REGION
# create_routing_blockage -name SRAM8_RB -layers {M1 M2 M3 M4 M5 M6} -boundary $SRAM8_RB_REGION

# Removed M5 routing blockage to fix LVS error
create_routing_blockage -name SRAM48_RB -layers {M1 M2 M3 M4 M6} -boundary $SRAM48_RB_REGION
create_routing_blockage -name SRAM8_RB -layers {M1 M2 M3 M4 M6} -boundary $SRAM8_RB_REGION

####################################
## Insert Boundary cells
####################################
set_boundary_cell_rules -left_boundary_cell {*/DCAP*}  -right_boundary_cell {*/DCAP*}
compile_advanced_boundary_cells -target_objects {ICACHE/ICACHE_SRAM/SRAM48 ICACHE/ICACHE_SRAM/SRAM8 DEFAULT_VA}


# # Write out floorplan

# ### Write floorplan for later re-use in ICC2
# write_floorplan -net_types {power ground} \
#   -include_physical_status {fixed locked} \
#   -read_def_options {-add_def_only_objects all -no_incremental} \
#   -force -output ${DESIGN_NAME}.fp/
