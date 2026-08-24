.section .text.start
.globl _start
_start:
  la s0, values
  li s1, 4
outer:
  mv t0, s0
  mv t1, s1
inner:
  lw t2, 0(t0)
  lw t3, 4(t0)
  bge t3, t2, ordered
  sw t3, 0(t0)
  sw t2, 4(t0)
ordered:
  addi t0, t0, 4
  addi t1, t1, -1
  bne t1, zero, inner
  addi s1, s1, -1
  bne s1, zero, outer
  mv t0, s0
  li t1, 5
  li t2, 0
checksum:
  lw t3, 0(t0)
  slli t4, t2, 3
  slli t5, t2, 1
  add t2, t4, t5
  add t2, t2, t3
  addi t0, t0, 4
  addi t1, t1, -1
  bne t1, zero, checksum
  li t6, 0x1000
  sw t2, 0(t6)
  li t6, 0x1ffc
  li s2, 1
  sw s2, 0(t6)
done: j done
.section .data
.align 2
values: .word 5,1,4,2,3
