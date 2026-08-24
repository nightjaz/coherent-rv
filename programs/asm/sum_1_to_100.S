.section .text.start
.globl _start
_start:
  li t0, 1
  li t1, 101
  li t2, 0
1: add t2, t2, t0
  addi t0, t0, 1
  blt t0, t1, 1b
  li t3, 0x1000
  sw t2, 0(t3)
  li t3, 0x1ffc
  li t4, 1
  sw t4, 0(t3)
2: j 2b
