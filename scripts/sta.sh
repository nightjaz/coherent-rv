#!/usr/bin/env bash
set -euo pipefail
./scripts/fetch_nangate45.sh
sta_bin=${OPENSTA_BIN:-/Users/futurixai/.local/opensta/bin/sta}
if [[ ! -x "$sta_bin" ]]; then
  echo "OpenSTA not found at $sta_bin. Set OPENSTA_BIN to its executable." >&2
  exit 1
fi
if [[ "${REUSE_MAPPED:-0}" != 1 ]]; then
yosys -q -s synthesis/map_core.ys
yosys -q -s synthesis/map_dcache_logic.ys
yosys -q -s synthesis/map_mesi.ys
yosys -q -s synthesis/map_soc_logic.ys
fi
./scripts/sta_sanitize.sh
"$sta_bin" -no_splash -exit synthesis/sta_core.tcl | tee build/core-sta.txt
"$sta_bin" -no_splash -exit synthesis/sta_dcache.tcl | tee build/dcache-sta.txt
"$sta_bin" -no_splash -exit synthesis/sta_mesi.tcl | tee build/mesi-sta.txt
"$sta_bin" -no_splash -exit synthesis/sta_soc.tcl | tee build/soc-sta.txt
