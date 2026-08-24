# Benchmarks and counters checkpoint

## What was built
Parallel sum, producer-consumer/message passing, a contended shared counter, false sharing, cache sweeps, and architectural/coherence instrumentation.
## Why it exists
Correct RTL needs measured performance and traffic evidence to support architectural conclusions.
## Inputs/outputs
Programs generate results; counters report cycles, retired instructions, cache events, bus transactions, invalidations, writebacks, and state occupancy.
## Important signals
Cycle/retired counts, hits/misses, BusRd/BusRdX/BusUpgr, and M/E/S/I line-cycles.
## FSM/datapath explanation
Counters increment only on completed events; retirement is held during memory stalls to prevent duplicate accounting.
## What could go wrong
Double counting a stalled instruction, comparing unlike workloads, dividing by zero, or reporting hand-entered numbers.
## Tests performed
Exact delayed-memory counter checks, single/dual parallel sum, producer-consumer, shared-counter contention, false sharing, and generated configuration tables.
## 5 likely interview questions
1. CPI versus IPC? 2. What is miss rate? 3. Why count occupancy? 4. How is speedup calculated? 5. What does false sharing cost?
