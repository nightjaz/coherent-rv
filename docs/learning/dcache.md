# Data-cache checkpoint

## What was built
A blocking direct-mapped write-back/write-allocate L1 D-cache with byte enables and MESI state per line.
## Why it exists
It reduces shared-memory traffic while retaining dirty data until eviction or coherence intervention.
## Inputs/outputs
CPU load/store ports connect to a BusRd/BusRdX/BusUpgr/writeback interface plus snoop ports.
## Important signals
Tags, data, MESI state, pending request, victim tag, hit/miss/writeback/invalidation and occupancy counters.
## FSM/datapath explanation
IDLE handles hits; WRITEBACK emits a dirty victim; ACQUIRE obtains ownership/data and merges a pending store.
## What could go wrong
Dropping dirty victims, writing back clean lines, losing byte masks, or returning stale data during simultaneous local write and snoop.
## Tests performed
Read hit/miss/refill, write hit/allocate, clean and dirty eviction, byte masks, counters, contention, and randomized coherence.
## 5 likely interview questions
1. Why write allocate? 2. When is writeback required? 3. Why store a victim tag? 4. How is a byte store merged? 5. Why does S need BusUpgr?
