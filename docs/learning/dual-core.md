# Dual-core integration checkpoint

## What was built
Two five-stage cores with private I/D caches, a round-robin bus, and shared data memory.
## Why it exists
Private caches create the stale-copy problem that the coherence protocol solves and measures.
## Inputs/outputs
The top exposes clock/reset, per-core cycle/retirement status, bus traffic, cache, invalidation, writeback, and MESI occupancy counters.
## Important signals
Per-core memory requests, bus grants, snoops, shared response, and aggregate performance counters.
## FSM/datapath explanation
Each core progresses independently until a miss; arbitration serializes shared-bus transactions and memory services the winner.
## What could go wrong
Starvation, dual grants, cross-core wiring errors, or treating two cores as useful without shared work.
## Tests performed
Sustained 50/50 arbitration, parallel sum, single-core baseline, producer-consumer, and dual-core random traces.
## 5 likely interview questions
1. Why private L1s? 2. What is serialized? 3. How is fairness achieved? 4. How is speedup computed? 5. What limits scaling?
