#!/bin/bash
################################################################################
## AS501
## Final Project
## Run Verdi Debug Script
################################################################################
## Copyright (c) 2024 by Smart Energy-Efficient Design Lab. (SEED), KAIST
## All rights reserved.
##
##                            Written by Hyungjoon Bae (jo_on@kaist.ac.kr)
##                            Supervised by Wanyeong Jung (wanyeong@kaist.ac.kr)
################################################################################

################################################################################
## Don't touch
##
    THIS_SCRIPT_DIR="$(realpath "$(dirname "$BASH_SOURCE")")"
    OUT_DIR="./out"

    # Check whether simulation directory exists
    if [ ! -d "$OUT_DIR" ];
    then
        echo "Error: $OUT_DIR does not exist"
        exit 1
    else
        cd $OUT_DIR
    fi
##
################################################################################

################################################################################
## Modify as needed
##
    # Run Verdi
    verdi -dbdir simv.daidir \
          -ssf   *.fsdb      \
          &
##
################################################################################