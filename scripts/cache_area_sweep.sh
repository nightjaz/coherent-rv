#!/usr/bin/env bash
set -euo pipefail
sta_bin=${OPENSTA_BIN:-/Users/futurixai/.local/opensta/bin/sta}
for size in 512 1024 2048 4096; do
  yosys -q -p "read_liberty -lib -ignore_miss_func physical/lib/NangateOpenCellLibrary_typical.lib; read_verilog -DSYNTHESIS -sv rtl/cache/mesi_controller.sv rtl/cache/dcache.sv; hierarchy -check -top dcache; chparam -set CACHE_SIZE $size dcache; proc; flatten; opt; memory_dff; memory_collect; opt; techmap; opt; dfflibmap -liberty physical/lib/NangateOpenCellLibrary_typical.lib; abc -liberty physical/lib/NangateOpenCellLibrary_typical.lib; clean; tee -o build/dcache-${size}-mapped-stat.txt stat -liberty physical/lib/NangateOpenCellLibrary_typical.lib; write_verilog -noattr build/dcache_${size}_mapped.v"
  sed -i.bak 's/wire signed /wire /g' "build/dcache_${size}_mapped.v"
  DCACHE_NETLIST="build/dcache_${size}_mapped.v" "$sta_bin" -no_splash -exit synthesis/sta_dcache_sweep.tcl > "build/dcache-${size}-sta.txt"
done
