#!/usr/bin/env bash
set -euo pipefail
mkdir -p build/riscv-tests verification/riscv-results
cc=${RISCV_GCC:-riscv64-elf-gcc}; objcopy=${RISCV_OBJCOPY:-riscv64-elf-objcopy}
tests=(add addi and andi auipc beq bge bgeu blt bltu bne jal jalr lb lbu lh lhu lui lw or ori sb sh sll slli slt slti sltiu sltu sra srai srl srli sub sw xor xori)
: > verification/riscv-results/rv32ui.log
for name in "${tests[@]}"; do
  "$cc" -march=rv32i_zicsr -mabi=ilp32 -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles \
    -I verification/riscv-tests/env/p -I verification/riscv-tests/isa/macros/scalar -T programs/link.ld \
    -o "build/riscv-tests/$name.elf" "verification/riscv-tests/isa/rv32ui/$name.S"
  "$objcopy" -O binary "build/riscv-tests/$name.elf" "build/riscv-tests/$name.bin"
  python3 scripts/bin2hex.py "build/riscv-tests/$name.bin" "build/riscv-tests/$name.hex"
  vvp build/riscv_arch_tb +IMAGE="build/riscv-tests/$name.hex" | tee -a verification/riscv-results/rv32ui.log
done
echo "PASS official riscv-tests RV32UI ${#tests[@]}/${#tests[@]}" | tee -a verification/riscv-results/rv32ui.log
