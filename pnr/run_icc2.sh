#!/bin/bash
################################################################################
## AS501
## Final Project
## Run IC Compiler II PnR - Full scripts
################################################################################
## Copyright (c) 2024 by Smart Energy-Efficient Design Lab. (SEED), KAIST
## All rights reserved.
##
##                            Written by Jihwan Cho (jihwancho@kaist.ac.kr)
##                            Supervised by Wanyeong Jung (wanyeong@kaist.ac.kr)
################################################################################

################################################################################
## Modify as needed
# Options - saed32rvt, saed32hvt, saed32lvt
STD_TYPE="saed32rvt"

################################################################################
## Don't touch
rm -rf ./out

# Run IC Compiler II

# 00_init_design
icc2_shell -f ./scripts/00_init_design.tcl     \
           -x "set STD_TYPE ${STD_TYPE}"       \
           -output_log_file ./00_init_design.log

# 01_place_opt
icc2_shell -f ./scripts/01_place_opt.tcl       \
           -x "set STD_TYPE ${STD_TYPE}"       \
           -output_log_file ./01_place_opt.log

# 02_clock_opt
icc2_shell -f ./scripts/02_clock_opt.tcl       \
           -x "set STD_TYPE ${STD_TYPE}"       \
           -output_log_file ./02_clock_opt.log

# 03_route_auto
icc2_shell -f ./scripts/03_route_auto.tcl      \
           -x "set STD_TYPE ${STD_TYPE}"       \
           -output_log_file ./03_route_auto.log

# 04_route_opt
icc2_shell -f ./scripts/04_route_opt.tcl       \
           -x "set STD_TYPE ${STD_TYPE}"       \
           -output_log_file ./04_route_opt.log

# 05_sign_off
icc2_shell -f ./scripts/05_sign_off.tcl        \
           -x "set STD_TYPE ${STD_TYPE}"       \
           -output_log_file ./05_sign_off.log

# 06_write_data
icc2_shell -f ./scripts/06_write_data.tcl      \
           -x "set STD_TYPE ${STD_TYPE}"       \
           -output_log_file ./06_write_data.log

# Make time log file
TIMESTAMP=$(date +%Y-%m-%d_%H:%M)
echo $TIMESTAMP >> ./out/$TIMESTAMP.txt

# Clean dirty files
rm -rf *.ems *.svf *.sgz
rm -rf *command.log
rm -rf *.dlib

# Move files to output directory
mv *.log signoff_fix_drc_run ./out/