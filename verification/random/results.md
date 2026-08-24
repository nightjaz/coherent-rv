# Generated random-regression matrix

| Operations | Seed | Litmus trials | Reads | Ownership reads | Upgrades | Invalidations | Result |
|---:|---:|---:|---:|---:|---:|---:|:---:|
| 100 | 1 | 100 | 157 | 20 | 147 | 165 | PASS |
| 100 | 305419896 | 100 | 161 | 17 | 151 | 166 | PASS |
| 100 | 3735928559 | 100 | 155 | 25 | 146 | 168 | PASS |
| 1,000 | 1 | 100 | 308 | 183 | 299 | 480 | PASS |
| 1,000 | 305419896 | 100 | 319 | 164 | 309 | 471 | PASS |
| 1,000 | 3735928559 | 100 | 307 | 191 | 298 | 486 | PASS |
| 100,000 | 1 | 100 | 17240 | 17614 | 17231 | 34843 | PASS |
| 100,000 | 305419896 | 100 | 17466 | 17183 | 17457 | 34638 | PASS |
| 100,000 | 3735928559 | 100 | 17521 | 17011 | 17513 | 34521 | PASS |

All nine runs compare every generated load with the testbench-only reference memory and require all nine stable MESI transition bins to be nonzero.
