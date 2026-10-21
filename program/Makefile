################################################################################
## AS501
## Final Project
## C to Hex Generator Makefile
################################################################################
## Copyright (c) 2024 by Smart Energy-Efficient Design Lab. (SEED), KAIST
## All rights reserved.
##
##                            Written by Michal Gorywoda (hotwater@kaist.ac.kr)
##                                       Hyungjoon Bae (jo_on@kaist.ac.kr)
##                            Supervised by Wanyeong Jung (wanyeong@kaist.ac.kr)
################################################################################
TOOLCHAIN = /opt/riscv/bin/riscv32-unknown-elf-

CC = $(TOOLCHAIN)gcc
OBJDUMP = objdump
OBJCOPY = objcopy
ELF2HEX = ./common/b2h_converter
CFLAGS = -march=rv32im_zicsr -mabi=ilp32 -Wl
MEMORY_BYTE_WIDTH = 4
TARGET ?= mlp
OUT_DIR = ./out

all: clean riscv

riscv:
	$(shell mkdir -p $(OUT_DIR))
	$(CC) $(CFLAGS),-Bstatic,-T,common/sections.lds,-Map=$(OUT_DIR)/mem.map,--strip-debug -ffreestanding -nostartfiles -o $(OUT_DIR)/$(TARGET)_riscv.elf ./common/start.s ./test_code/$(TARGET).c -lm -D RISCV
	$(TOOLCHAIN)objdump --disassemble-all -d $(OUT_DIR)/$(TARGET)_riscv.elf > $(OUT_DIR)/$(TARGET)_riscv.dis
	$(TOOLCHAIN)objcopy -O binary $(OUT_DIR)/$(TARGET)_riscv.elf $(OUT_DIR)/$(TARGET)_riscv.bin
	$(ELF2HEX) $(OUT_DIR)/$(TARGET)_riscv.bin $(OUT_DIR)/$(TARGET)_riscv.hex $(MEMORY_BYTE_WIDTH) 32768

clean:
	rm -f $(OUT_DIR)/*.elf
	rm -f $(OUT_DIR)/*.hex
	rm -f $(OUT_DIR)/*.dis
	rm -f $(OUT_DIR)/*.bin
	rm -f $(OUT_DIR)/mem.map