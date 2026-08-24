# Random coherence verification checkpoint

## What was built
A dual-cache randomized load/store generator with a testbench-only reference memory and transition counters.
## Why it exists
Random timing and address combinations reach races that short directed sequences miss.
## Inputs/outputs
Operation count and seed parameters drive core/address/write choices; every read is compared to the reference model.
## Important signals
LFSR, reference words, cache states/tags, bus command/grant, read result, and nine MESI transition bins.
## FSM/datapath explanation
Each generated operation completes at a synchronization point before the reference state advances; same-line addresses are deliberately frequent.
## What could go wrong
A model that copies the RTL bug, insufficient seeds, no contention, or checking memory before dirty lines write back.
## Tests performed
100, 1,000, and 100,000 operations across multiple seeds, plus 100 interleaved message-passing trials.
## 5 likely interview questions
1. Why a reference model? 2. Why bias same lines? 3. What is a seed for? 4. What race was found? 5. Why track transitions?
