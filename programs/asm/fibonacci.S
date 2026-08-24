.section .text.start
.globl _start
_start:
  li t0, 0
  li t1, 1
  li t2, 10
1: beq t2, zero, 2f
  add t3, t0, t1
  mv t0, t1
  mv t1, t3
  addi t2, t2, -1
  j 1b
2: li t4, 0x1000
  sw t0, 0(t4)
  li t4, 0x1ffc
  li t5, 1
  sw t5, 0(t4)
3: j 3b
