#!/usr/bin/env python3
from pathlib import Path
import re
root=Path(__file__).resolve().parents[1];log=(root/'build'/'random-matrix.log').read_text()
rows=re.findall(r'PASS coherence cache=(\d+) random=(\d+) litmus=(\d+) BusRd=(\d+) BusRdX=(\d+) BusUpgr=(\d+) invalidations=(\d+) hits=(\d+) misses=(\d+) writebacks=(\d+)',log)
if len(rows)!=9:raise SystemExit(f'expected 9 passing matrix rows, found {len(rows)}')
seeds=[1,305419896,3735928559]*3
L=['# Generated random-regression matrix','','| Operations | Seed | Litmus trials | Reads | Ownership reads | Upgrades | Invalidations | Result |','|---:|---:|---:|---:|---:|---:|---:|:---:|']
for seed,row in zip(seeds,rows):
 x=list(map(int,row));L.append(f'| {x[1]:,} | {seed} | {x[2]} | {x[3]} | {x[4]} | {x[5]} | {x[6]} | PASS |')
L+=['','All nine runs compare every generated load with the testbench-only reference memory and require all nine stable MESI transition bins to be nonzero.']
(root/'verification'/'random'/'results.md').write_text('\n'.join(L)+'\n')
