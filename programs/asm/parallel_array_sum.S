# Core 0 and Core 1 use the same loop with different [start,end) pointers.
# Core 1 publishes its partial sum then flag=1. Core 0 polls the flag,
# combines both partials, and stores the final result. The executable testbench
# encodes this source without requiring a proprietary RISC-V toolchain.

loop:
    lw   x4, 0(x1)
    add  x3, x3, x4
    addi x1, x1, 4
    blt  x1, x2, loop
