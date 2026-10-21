################################################################################
## AS501
## Final Project
## IC Compiler II common setup
################################################################################
## Copyright (c) 2024 by Smart Energy-Efficient Design Lab. (SEED), KAIST
## All rights reserved.
##
##                            Written by Jihwan Cho (jihwancho@kaist.ac.kr)
##                            Supervised by Wanyeong Jung (wanyeong@kaist.ac.kr)
################################################################################

################################################################################
## Don't touch

set DESIGN_NAME 		CPU_TOP
set LIBRARY_SUFFIX		.dlib
set DESIGN_LIBRARY 		${DESIGN_NAME}${LIBRARY_SUFFIX}

##################################
## Reference Libraries
##################################

# NDM
set NDM_DIR              ./ndm
set NDM_LIST             [list $NDM_DIR/$STD_TYPE.ndm \
                               $NDM_DIR/saed32sram.ndm]

##################################
## Technology Files and setup
##################################

######### 00_init_design #########
# Tech file
set TECH_FILE                            /technology/SAED32/tech/milkyway/saed32nm_1p9m_mw.tf

# Parasitic RC Model files
set PARASITIC_WORST                      C_WORST
set TLUPLUS_FILE($PARASITIC_WORST)       /technology/SAED32/tech/star_rcxt/saed32nm_1p9m_Cmax.tluplus
set LAYER_MAP_FILE($PARASITIC_WORST)     /technology/SAED32/tech/star_rcxt/saed32nm_tf_itf_tluplus.map

set PARASITIC_BEST                       C_BEST
set TLUPLUS_FILE($PARASITIC_BEST)        /technology/SAED32/tech/star_rcxt/saed32nm_1p9m_Cmin.tluplus
set LAYER_MAP_FILE($PARASITIC_BEST)      /technology/SAED32/tech/star_rcxt/saed32nm_tf_itf_tluplus.map

# Placement Site & Symmetry
set SITE_DEFAULT                         unit
set SITE_SYMMETRY                        Y

# Routing Layer setup
set HORIZONTAL_ROUTING_LAYER_LIST        {M1 M3 M5 M7 M9}
set VERTICAL_ROUTING_LAYER_LIST          {M2 M4 M6 M8}
set MIN_ROUTING_LAYER	  	             M1
set MAX_ROUTING_LAYER 		             M6

######### 01_place_opt ##########
# Cells used for CTS
set CTS_CELLS                            {*/NBUFF* */INVX* */DEL*}

# TIE Cells
set TIE_CELLS                            {*/TIE*}

######### 02_clock_opt ##########
#

######### 03_route_auto #########
set ANTENNA_RULE                         /technology/SAED32/tech/milkyway/saed32nm_ant_1p9m.tcl

######### 04_route_opt ##########
#

######### 05_sign_off ###########
# Filler Cells
set FILLER_CELLS                         {*/SHFILL128_* */SHFILL64_* */SHFILL3_* */SHFILL2_* */SHFILL1_*}

# ICV In-Design DRC
set ICV_DRC_RULE_FILE                    /technology/SAED32/tech/icv_drc/saed32nm_1p9m_drc_rules.rs

######### 06_write_data #########
#

##################################
## Design Data
##################################

# Verilog(Netlist), UPF(Power intent), SDC(Timing Constraint)
set SYN_OUT_DIR                          ../syn/out/
set DESIGN_DATA_DIR                      ./design_data
set VERILOG_NETLIST_FILE                 ${SYN_OUT_DIR}/${DESIGN_NAME}.mapped.v
set SDC_FILE                             ${SYN_OUT_DIR}/${DESIGN_NAME}.mapped.sdc
set UPF_FILE                             ${DESIGN_DATA_DIR}/${DESIGN_NAME}.upf

##################################
## User TCL scripts
##################################

# User TCL scripts sourced while executing the main PnR scripts (00_init_design -> 01_place_opt -> 02_clock_opt -> 03_route_auto -> 04_route_opt -> 05_sign_off -> 06_write_data)
# These TCL scripts should be modified depending on your design
# 00_init_design.tcl
set TCL_FLOORPLAN                        ./scripts_user/floorplan.tcl
set TCL_PNS                              ./scripts_user/pns.tcl
set TCL_MCMM_SETUP                       ./scripts_user/mcmm.tcl
# 01_place_opt.tcl
set TCL_CTS_NDR                          ./scripts_user/cts_ndr.tcl

##################################
## Multi-thread setup
##################################

# Set max number of cores
# set_host_options -max_cores 8
set_host_options -max_cores 64


set sh_continue_on_error false

##################################
## Save Block label
##################################

# Block is saved at the end of each PnR stage (save_block) with following labels
set INIT_DESIGN_BLOCK_LABEL              init_design
set PLACE_OPT_BLOCK_LABEL                place_opt
set CLOCK_OPT_BLOCK_LABEL                clock_opt
set ROUTE_AUTO_BLOCK_LABEL               route_auto
set ROUTE_OPT_BLOCK_LABEL                route_opt
set SIGN_OFF_BLOCK_LABEL                 sign_off
set WRITE_DATA_BLOCK_LABEL               write_data

##################################
## Output/Report Directory
##################################

## Directories
set OUTPUT_DIR	./out/
set REPORT_DIR	$OUTPUT_DIR/rpt

if !{[file exists $OUTPUT_DIR]} {file mkdir $OUTPUT_DIR}
if !{[file exists $REPORT_DIR]} {file mkdir $REPORT_DIR}



