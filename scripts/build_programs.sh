#!/usr/bin/env bash
set -euo pipefail
mkdir -p programs/binaries build/programs
cc=${RISCV_GCC:-riscv64-elf-gcc}
objcopy=${RISCV_OBJCOPY:-riscv64-elf-objcopy}
for source in programs/asm/sum_1_to_100.S programs/asm/array_sum.S programs/asm/fibonacci.S programs/asm/memory_copy.S programs/asm/tiny_sort.S; do
  name=$(basename "$source" .S)
  "$cc" -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -mno-relax -Wl,--no-relax -T programs/link.ld "$source" -o "build/programs/$name.elf"
  "$objcopy" -O binary "build/programs/$name.elf" "build/programs/$name.bin"
  python3 scripts/bin2hex.py "build/programs/$name.bin" "programs/binaries/$name.hex"
done
