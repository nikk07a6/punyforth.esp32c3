/*
    s8  : xt -
    s9  : pc - forth instruction pointer
    s10 : dp - dstack pointer
    s11 : rp - rstack pointer
*/

.macro NEXT
    lw   s8, 0(s9)      // xt <- [pc]
    addi s9, s9, 4      // pc = pc + 4
    lw   t0, 0(s8)      // t0 <- [xt]
    jr   t0             // jump -> [xt]
.endm

.macro DEFPRIMITIVE flags, label, namelen, name, link=554921b-4
    .section .rodata
    .align WORD_ALIGN
name_\label:
    .word  \link
554921:
    .byte  \flags + \namelen
    .ascii "\name"
    .align WORD_ALIGN
    .globl xt_\label
xt_\label :
    .word  code_\label
    .section .irom0.text
    .align WORD_ALIGN
    .globl code_\label
code_\label :
.endm

.macro DEFWORD flags, label, namelen, name, link=554921b-4
    .section .rodata
    .align WORD_ALIGN
name_\label:
    .word  \link
554921:
    .byte  \flags + \namelen
    .ascii "\name"
    .align WORD_ALIGN
    .globl xt_\label
xt_\label :
    .word  ENTERCOL
.endm

.macro LBL label
    .word  \label - .
.endm

.macro DPUSH reg
    addi s10, s10, -CELLS
    sw   \reg, 0(s10)
.endm

.macro DPOP reg
    lw   \reg, 0(s10)
    addi s10, s10, CELLS
.endm

.macro RPUSH reg
    addi s11, s11, -CELLS
    sw   \reg, 0(s11)
.endm

.macro RPOP reg
    lw   \reg, 0(s11)
    addi s11, s11, CELLS
.endm

.macro READTOS1 reg
    lw   \reg, 0(s10)
.endm

.macro READTOS2 reg
    lw   \reg, CELLS(s10)
.endm

.macro READTOS3 reg
    lw   \reg, 2*CELLS(s10)
.endm

.macro READTOS4 reg
    lw   \reg, 3*CELLS(s10)
.endm

.macro WRTETOS1 reg
    sw   \reg, 0(s10)
.endm

.macro WRTETOS2 reg
    sw   \reg, CELLS(s10)
.endm

.macro WRTETOS3 reg
    sw   \reg, 2*CELLS(s10)
.endm

.macro WRTETOS4 reg
    sw   \reg, 3*CELLS(s10)
.endm
