# Static timing checkpoint

## What was built
OpenSTA constraints and reports for mapped core, D-cache, MESI controller, and dual-core logic.
## Why it exists
Synthesis area does not show whether the logic meets a clock period or which path limits frequency.
## Inputs/outputs
Mapped Nangate45 netlists and SDC clocks/I/O delays produce path reports, slack, TNS, and inferred pre-layout Fmax.
## Important signals
Clock, asynchronous reset false path, data arrival/required time, startpoint, endpoint, slack, and memory-macro boundaries.
## FSM/datapath explanation
STA propagates library delays over every timing arc and compares latest arrival with setup requirements without simulation vectors.
## What could go wrong
Unconstrained paths, timing behavioral SRAMs as flops, missing wire RC, or presenting pre-layout results as signoff.
## Tests performed
Before/after core retirement gating and D-cache occupancy-tree runs use identical libraries and 10 ns constraints.
## 5 likely interview questions
1. What is setup slack? 2. How is Fmax estimated? 3. Why black-box SRAM? 4. What is TNS? 5. Why can post-route timing differ?
