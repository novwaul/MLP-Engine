################################################################################
## AS501
## Final Project
## Multi-Corner-Multi-Mode Setup
################################################################################
## Copyright (c) 2024 by Smart Energy-Efficient Design Lab. (SEED), KAIST
## All rights reserved.
##
##                            Written by Jihwan Cho (jihwancho@kaist.ac.kr)
##                            Supervised by Wanyeong Jung (wanyeong@kaist.ac.kr)
################################################################################

################################################################################
## Don't touch

# MCMM setup

########################################
## Mode, corner and scenario creation
########################################

create_mode func

create_corner ff1p16v125c
create_corner ff1p16vn40c
create_corner ss0p95v125c
create_corner ss0p95vn40c

create_scenario -name func_ff1p16v125c -mode func -corner ff1p16v125c
create_scenario -name func_ff1p16vn40c -mode func -corner ff1p16vn40c
create_scenario -name func_ss0p95v125c -mode func -corner ss0p95v125c
create_scenario -name func_ss0p95vn40c -mode func -corner ss0p95vn40c

########################################
## Populate modes, corners and scenarios
########################################

# mode
current_mode func
read_sdc $SDC_FILE

# corner
current_corner ff1p16v125c
set_parasitic_parameters -early_spec $PARASITIC_BEST -late_spec $PARASITIC_BEST
set_process_number 1.01
set_temperature 125
set_voltage 1.16
set_voltage 1.16 -object_list VDD
set_voltage 0.0 -object_list VSS

current_corner ff1p16vn40c
set_parasitic_parameters -early_spec $PARASITIC_BEST -late_spec $PARASITIC_BEST
set_process_number 1.01
set_temperature -40
set_voltage 1.16
set_voltage 1.16 -object_list VDD
set_voltage 0.0 -object_list VSS

current_corner ss0p95v125c
set_parasitic_parameters -early_spec $PARASITIC_WORST -late_spec $PARASITIC_WORST
set_process_number 0.99
set_temperature 125
set_voltage 0.95
set_voltage 0.95 -object_list VDD
set_voltage 0.0 -object_list VSS

current_corner ss0p95vn40c
set_parasitic_parameters -early_spec $PARASITIC_WORST -late_spec $PARASITIC_WORST
set_process_number 0.99
set_temperature -40
set_voltage 0.95
set_voltage 0.95 -object_list VDD
set_voltage 0.0 -object_list VSS