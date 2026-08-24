#!/usr/bin/env bash
set -euo pipefail
./scripts/fetch_nangate45.sh
sta_bin=${OPENSTA_BIN:-/Users/futurixai/.local/opensta/bin/sta}
[[ -x "$sta_bin" ]] || { echo "OpenSTA not found at $sta_bin" >&2; exit 1; }
iverilog -g2012 -DLEGACY_COUNTONES_OCCUPANCY -s dcache_tb -o build/dcache_before_occupancy_opt_tb rtl/cache/mesi_controller.sv rtl/cache/dcache.sv tb/cache/dcache_tb.sv
vvp build/dcache_before_occupancy_opt_tb | tee build/dcache-before-occupancy-opt-functional.log
yosys -q -s synthesis/map_dcache_countones_baseline.ys
sed -i.bak 's/wire signed /wire /g' build/dcache_before_occupancy_opt_mapped.v
"$sta_bin" -no_splash -exit synthesis/sta_dcache_countones_baseline.tcl | tee build/dcache-before-occupancy-opt-sta.txt
