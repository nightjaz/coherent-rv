.section .text.start
.globl _start
_start:
  la t0, values
  li t1, 8
  li t2, 0
1: lw t3, 0(t0)
  add t2, t2, t3
  addi t0, t0, 4
  addi t1, t1, -1
  bne t1, zero, 1b
  li t4, 0x1000
  sw t2, 0(t4)
  li t4, 0x1ffc
  li t5, 1
  sw t5, 0(t4)
2: j 2b
.section .data
.align 2
values: .word 1,2,3,4,5,6,7,8
