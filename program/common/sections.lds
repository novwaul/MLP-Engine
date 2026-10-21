################################################################################
## AS501
## Final Project
## RISC-V Linker Script
################################################################################
## Copyright (c) 2024 by Smart Energy-Efficient Design Lab. (SEED), KAIST
## All rights reserved.
##
##                            Written by Michal Gorywoda (hotwater@kaist.ac.kr)
##                                       Hyungjoon Bae (jo_on@kaist.ac.kr)
##                            Supervised by Wanyeong Jung (wanyeong@kaist.ac.kr)
################################################################################

MEMORY
{
    INSTRAM(rwx) : ORIGIN = 0x00000000, LENGTH = 0x00004000 # 16 KB (0x00000000 ~ 0x00003FFF)
    DATARAM(rwx) : ORIGIN = 0x00004000, LENGTH = 0x02000000 # 32 MB (0x00004000 ~ 0x02003FFF)
}
    PROVIDE(_estack = 0x02004000);

SECTIONS
{
    .text :
    {
        PROVIDE(_start = .);
        . = ALIGN(4);
        _stext = .;
        *(.text)
        *(.text*)
        *(.rodata)
        *(.rodata*)
        *(.srodata)
        *(.srodata*)
        . = ALIGN(4);
        _etext = .;
        _sidata = _etext;
    } > INSTRAM

    .data : AT (_sidata)
    {
        . = ALIGN(4);
        _sdata = .;
        PROVIDE( __global_pointer$ = . + (4K / 2) );
        . = ALIGN(4);
        *(.data)
        *(.data*)
        *(.sdata)
        *(.sdata*)
        . = ALIGN(4);
        _edata = .;
    } > DATARAM
}