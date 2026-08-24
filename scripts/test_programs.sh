#!/usr/bin/env bash
set -euo pipefail
./scripts/build_programs.sh
mkdir -p build
rtl=(rtl/core/alu.sv rtl/core/immediate_gen.sv rtl/core/control_unit.sv rtl/core/register_file.sv rtl/core/hazard_unit.sv rtl/core/forwarding_unit.sv rtl/core/rv32_core.sv)
tests=(sum_1_to_100:5050 array_sum:36 fibonacci:55 memory_copy:100 tiny_sort:12345)
for item in "${tests[@]}"; do
  name=${item%%:*}
  expected=${item##*:}
  iverilog -g2012 -Wall -s program_tb \
    -Pprogram_tb.HEX_FILE="\"programs/binaries/${name}.hex\"" \
    -Pprogram_tb.EXPECTED="$expected" -Pprogram_tb.TEST_NAME="\"${name}\"" \
    -o "build/program_${name}" "${rtl[@]}" tb/core/program_tb.sv
  vvp "build/program_${name}"
done
