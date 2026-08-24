#!/usr/bin/env bash
set -euo pipefail
for netlist in build/rv32_core_mapped.v build/dcache_logic_mapped.v build/dual_core_soc_logic_mapped.v; do
  [[ -f "$netlist" ]] || continue
  sed -i.bak 's/wire signed /wire /g' "$netlist"
done
if [[ -f build/dual_core_soc_logic_mapped.v ]]; then
  perl -0pi -e 's/simple_memory #\(\s*\.ADDRESS_WIDTH\([^)]+\),\s*\.LINE_BYTES\([^)]+\)\s*\) (\w+) \(/simple_memory $1 (/g' build/dual_core_soc_logic_mapped.v
fi
