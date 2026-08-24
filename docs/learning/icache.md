# Instruction-cache checkpoint

## What was built
A blocking, direct-mapped, read-only parameterized L1 instruction cache.
## Why it exists
It hides line-fill latency and gives each core a private instruction working set.
## Inputs/outputs
CPU request/address returns a word/ready; the refill side requests an aligned line and accepts line data/ready.
## Important signals
Valid, tag, index, word offset, `waiting`, pending address, hit count, and miss count.
## FSM/datapath explanation
An IDLE hit returns immediately; a miss records the address, waits for a line, installs tag/data, and returns the selected word.
## What could go wrong
Wrong tag slicing, returning a stale fill to a redirected address, bad alignment, or illegal non-power-of-two parameters.
## Tests performed
First miss, delayed refill, hit, conflict eviction, exact counters, 512 B–4 KiB sizes, and 16/32/64-byte lines.
## 5 likely interview questions
1. Why direct mapped? 2. How is a word selected? 3. Why block on a miss? 4. What causes a conflict miss? 5. Why validate parameters?
