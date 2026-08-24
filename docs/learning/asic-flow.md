# Synthesis and timing learning checkpoint

## What was built

Reproducible Yosys synthesis for the core, D-cache, and hierarchical SoC; ABC standard-cell mapping of the core; an SDC constraint file; and OpenSTA setup analysis using the commit-pinned Nangate45 typical library.

## Why and interfaces

RTL simulation establishes behavior but not realizability or timing. Synthesis lowers processes, registers, and memories into a netlist. Mapping selects characterized cells. STA propagates library delays between sequential endpoints under clock and I/O constraints without test vectors.

## Failure modes and tests

Unsupported SystemVerilog can prevent synthesis; inferred cache arrays may expand into flops instead of SRAM macros; missing I/O delays create unconstrained paths; ideal-clock/no-parasitic timing can overstate Fmax; and a positive 100 MHz slack does not imply post-route closure. The generated results, rather than this learning note, are the source of current cell counts and timing values.

## Interview questions

1. Why can pre-layout and post-route timing differ substantially?
2. What does positive setup slack mean?
3. Why are cache data arrays poor candidates for flip-flop implementation?
4. What is the difference between generic synthesis and cell mapping?
5. Why is a pre-layout Fmax estimate not signoff timing?

## Why it exists
The flow produces reproducible realizability, area, and timing evidence.
## Inputs/outputs
RTL and Liberty inputs produce mapped netlists, statistics, and STA reports.
## Important signals
Clock/reset constraints, setup slack, sequential area, and memory boundaries.
## FSM/datapath explanation
Yosys lowers RTL, ABC maps cells, and OpenSTA propagates timing arcs.
## What could go wrong
Unmapped SRAM, unconstrained paths, or presenting pre-layout timing as signoff.
## Tests performed
Four mapped scopes, per-block timing, and same-constraint optimization comparisons.
## 5 likely interview questions
See the five questions above.
