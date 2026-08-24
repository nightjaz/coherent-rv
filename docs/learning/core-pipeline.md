# Core and pipeline learning checkpoint

## What was built

An in-house RV32I five-stage pipeline with register file, immediate generator, decoder, ALU, forwarding, load-use interlock, control redirect, memory alignment, and architectural counters.

## Why and interfaces

Pipelining overlaps instructions for throughput; hazards preserve the sequential ISA result. Instruction and data memory are explicit request/ready interfaces. Retirement exposes PC and instruction for verification.

## Failure modes and tests

Wrong forwarding priority silently uses stale operands; missing WB-to-ID bypass loses values separated by three instructions; a flushed store can corrupt memory; signed loads/comparisons can zero-extend accidentally. The loop regression stresses ALU dependencies, forwarding, signed BLT, repeated redirects, store, and the x0-based address.

## Interview questions

1. Why can an ALU result forward from EX/MEM but a load result cannot?
2. Why does a taken EX-stage branch kill two younger stages?
3. What freezes during a data-cache miss?
4. Why is the register file write-first?
5. How are CPI and IPC derived from the counters?

## Why it exists
The pipeline overlaps work while hazards preserve sequential behavior.
## Inputs/outputs
Instruction/data request-ready ports plus retirement and counter outputs.
## Important signals
Stage-valid bits, forwarding selects, stall, and redirect.
## FSM/datapath explanation
Stages advance together unless memory stalls; load-use inserts a bubble and redirect kills younger stages.
## What could go wrong
Bad forwarding priority, duplicate retirement, or a killed store reaching memory.
## Tests performed
Directed hazards, delayed memory, local and upstream ISA regressions.
## 5 likely interview questions
See the five questions above.
