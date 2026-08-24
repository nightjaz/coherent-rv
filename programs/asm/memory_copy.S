.section .text.start
.globl _start
_start:
  la t0, source
  la t1, destination
  li t2, 4
1: lw t3, 0(t0)
  sw t3, 0(t1)
  addi t0, t0, 4
  addi t1, t1, 4
  addi t2, t2, -1
  bne t2, zero, 1b
  la t1, destination
  li t2, 4
  li t4, 0
2: lw t3, 0(t1)
  add t4, t4, t3
  addi t1, t1, 4
  addi t2, t2, -1
  bne t2, zero, 2b
  li t5, 0x1000
  sw t4, 0(t5)
  li t5, 0x1ffc
  li t6, 1
  sw t6, 0(t5)
3: j 3b
.section .data
.align 2
source: .word 10,20,30,40
destination: .word 0,0,0,0
