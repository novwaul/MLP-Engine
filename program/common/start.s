################################################################################
## AS501
## Final Project
## RISC-V Startup Assembly Code
################################################################################
## Copyright (c) 2024 by Smart Energy-Efficient Design Lab. (SEED), KAIST
## All rights reserved.
##
##                            Written by Michal Gorywoda (hotwater@kaist.ac.kr)
##                                       Hyungjoon Bae (jo_on@kaist.ac.kr)
##                            Supervised by Wanyeong Jung (wanyeong@kaist.ac.kr)
################################################################################

.section .text

start:
# Initialize stack pointer
lui x2, %hi(_estack)
addi x2, x2, %lo(_estack)
