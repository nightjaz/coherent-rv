#!/usr/bin/env bash
set -euo pipefail
mkdir -p build
: > build/cache-sweep.log
rtl=(rtl/cache/mesi_controller.sv rtl/cache/dcache.sv rtl/cache/icache.sv rtl/interconnect/bus_arbiter.sv rtl/interconnect/coherence_bus.sv rtl/memory/simple_memory.sv)
for size in 512 1024 2048 4096; do
  iverilog -g2012 -s coherence_tb -Pcoherence_tb.CACHE_SIZE="$size" -o "build/coherence_${size}" "${rtl[@]}" tb/assertions/coherence_assertions.sv tb/assertions/cache_assertions.sv tb/coherence/coherence_tb.sv
  vvp "build/coherence_${size}" | tee -a build/cache-sweep.log
  iverilog -g2012 -s cache_capacity_tb -Pcache_capacity_tb.CACHE_SIZE="$size" -o "build/capacity_${size}" rtl/cache/icache.sv tb/cache/cache_capacity_tb.sv
  vvp "build/capacity_${size}" | tee -a build/cache-sweep.log
done
for line in 16 32 64; do
  iverilog -g2012 -s cache_capacity_tb -Pcache_capacity_tb.LINE_SIZE="$line" -o "build/line_${line}" rtl/cache/icache.sv tb/cache/cache_capacity_tb.sv
  vvp "build/line_${line}" | tee -a build/cache-sweep.log
done
