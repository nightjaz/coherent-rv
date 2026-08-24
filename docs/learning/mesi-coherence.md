# MESI and coherence learning checkpoint

## What was built

Two private blocking D-caches, stable MESI line states, IS/IM/SM/MI-equivalent blocking control, dirty intervention, a shared snooping bus, and round-robin arbitration.

## Why and interfaces

Without coherence, a private cached copy becomes stale after another core writes. BusRd obtains a readable line, BusRdX obtains ownership and data, BusUpgr invalidates peers without refetching data, and writeback preserves a dirty victim. A snoop exposes hit, supply, and complete-line data signals.

## Failure modes and tests

Competing S→M upgrades exposed a real transient race: the losing queued BusUpgr had already been invalidated, so it must retry as BusRdX. Other failures include M/M ownership, returning stale memory instead of dirty intervention data, losing byte writes, and acknowledging before a bus grant. Directed cases, simultaneous writers, dirty eviction, and a 100,000-operation reference-model run cover these risks.

## Interview questions

1. Why is E different from S?
2. Why does E→M require no bus transaction?
3. When must M update memory?
4. Why can both caches be S but never M?
5. Why must a queued BusUpgr sometimes become BusRdX?

## Why it exists
MESI prevents stale private copies while retaining useful sharing.
## Inputs/outputs
CPU requests, bus commands, snoops, line data, grants, and responses.
## Important signals
M/E/S/I state, pending command, peer hit/supply, and traffic counters.
## FSM/datapath explanation
Stable line states combine with IDLE/WRITEBACK/ACQUIRE transaction states.
## What could go wrong
Conflicting owners, lost dirty data, or simultaneous local-write/snoop stale data.
## Tests performed
All nine transitions, false sharing, assertions, litmus interleavings, and random matrices.
## 5 likely interview questions
See the five questions above.
