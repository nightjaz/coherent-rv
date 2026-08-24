Yes. For #3, I would make it **substantially more than “two CPUs connected together.”** The project should be a proper **dual-core cache-coherent RV32I SoC**, with enough RTL, verification, performance work, and ASIC flow that you can credibly use it for processor design / ASIC / RTL / verification roles.

This directly attacks the gaps implied by the IBM JD: digital logic, computer architecture, processor pipelines, VLSI flow, memory technologies, verification, and processor development.  

Below is the build specification I would hand to a coding agent.

---

# Project: CoherentRV

## Dual-Core Cache-Coherent RV32I Processor SoC

### Core objective

Design, verify, synthesize, and benchmark a **dual-core 32-bit RISC-V processor system** from RTL.

Each CPU should have:

* RV32I ISA support
* 5-stage pipeline
* private L1 instruction cache
* private L1 data cache

The two private data caches should remain coherent using a simplified **MESI cache-coherence protocol** over a shared interconnect.

Final architecture:

```text
                  ┌─────────────────┐
                  │  Shared Memory  │
                  └────────┬────────┘
                           │
                  Shared Interconnect
                    /             \
                   /               \
          ┌───────┴───────┐ ┌─────┴─────────┐
          │    Core 0     │ │    Core 1     │
          │               │ │               │
          │ 5-stage RV32I │ │ 5-stage RV32I │
          └───┬────────┬──┘ └──┬─────────┬──┘
              │        │       │         │
            L1 I$    L1 D$   L1 I$     L1 D$
                       │                 │
                       └──── MESI ───────┘
```

The key demonstration:

```text
Core 0 writes X
        ↓
Core 1 had X cached
        ↓
coherence protocol invalidates / updates state
        ↓
Core 1 later reads the correct value
```

---

# What this project needs to prove

This is not just a functional CPU.

The repository needs visible evidence of:

### RTL design

* datapaths
* FSMs
* pipelining
* arbitration
* cache controllers

### Computer architecture

* instruction execution
* hazards
* forwarding
* branch handling
* cache behavior

### Memory systems

* tags
* sets
* cache lines
* hits/misses
* write-back
* eviction
* coherence

### Verification

* directed tests
* assertions
* randomized tests
* ISA tests
* coherence tests
* coverage

### ASIC/VLSI

* synthesis
* STA
* area
* critical paths
* optional RTL → GDS flow

That combination is what makes the project valuable.

---

# PHASE 0 — Coding-agent rules

Give the agent this first:

> We are implementing a synthesizable dual-core RV32I processor SoC in SystemVerilog.
>
> This is a hardware-design project, not a software simulation of a CPU.
>
> Rules:
>
> 1. All processor/cache/interconnect functionality must be synthesizable RTL.
> 2. Testbench-only constructs must remain separate from design RTL.
> 3. Do not hide functionality inside behavioral software models.
> 4. Every module must have a documented interface.
> 5. Every state machine must have its states documented.
> 6. Build and verify one subsystem at a time.
> 7. Do not implement dual-core coherence until one CPU and one cache work correctly.
> 8. Prefer correctness and verification over feature count.
> 9. Every architectural feature requires tests.
> 10. Every coherence transition requires an assertion or targeted verification scenario.
> 11. Use parameters rather than hard-coded cache dimensions where reasonable.
> 12. Keep the design compatible with Verilator and open-source synthesis tools where possible.
> 13. Maintain docs/architecture.md as the architecture evolves.
> 14. Never declare a milestone complete merely because the RTL compiles.
>
> At every milestone:
>
> * lint
> * simulate
> * run regression tests
> * document known limitations
> * commit only after tests pass

---

# PHASE 1 — Repository

Structure:

```text
CoherentRV/
│
├── rtl/
│   ├── core/
│   │   ├── rv32_core.sv
│   │   ├── fetch_stage.sv
│   │   ├── decode_stage.sv
│   │   ├── execute_stage.sv
│   │   ├── memory_stage.sv
│   │   ├── writeback_stage.sv
│   │   ├── register_file.sv
│   │   ├── alu.sv
│   │   ├── immediate_gen.sv
│   │   ├── control_unit.sv
│   │   ├── hazard_unit.sv
│   │   └── forwarding_unit.sv
│   │
│   ├── cache/
│   │   ├── icache.sv
│   │   ├── dcache.sv
│   │   ├── cache_controller.sv
│   │   └── mesi_controller.sv
│   │
│   ├── interconnect/
│   │   ├── coherence_bus.sv
│   │   ├── bus_arbiter.sv
│   │   └── memory_controller.sv
│   │
│   ├── memory/
│   │   └── simple_memory.sv
│   │
│   └── soc/
│       └── dual_core_soc.sv
│
├── tb/
│   ├── core/
│   ├── cache/
│   ├── coherence/
│   ├── soc/
│   └── assertions/
│
├── programs/
│   ├── asm/
│   ├── c/
│   └── binaries/
│
├── scripts/
│   ├── build.sh
│   ├── test.sh
│   ├── synth.sh
│   └── benchmark.py
│
├── verification/
│   ├── riscv-tests/
│   ├── random/
│   └── coverage/
│
├── synthesis/
│
├── physical/
│
├── docs/
│   ├── architecture.md
│   ├── pipeline.md
│   ├── cache.md
│   ├── mesi.md
│   ├── verification.md
│   └── results.md
│
├── Makefile
├── README.md
└── LICENSE
```

---

# PHASE 2 — First build a single-cycle RV32I CPU

Do **not** start with pipelining.

Have the agent build the architectural datapath first.

Supported base ISA:

### Arithmetic

```text
ADD
SUB
ADDI
```

### Logical

```text
AND
OR
XOR
ANDI
ORI
XORI
```

### Shift

```text
SLL
SRL
SRA
SLLI
SRLI
SRAI
```

### Comparison

```text
SLT
SLTU
SLTI
SLTIU
```

### Loads

```text
LB
LH
LW
LBU
LHU
```

### Stores

```text
SB
SH
SW
```

### Branches

```text
BEQ
BNE
BLT
BGE
BLTU
BGEU
```

### Control

```text
JAL
JALR
LUI
AUIPC
```

That's essentially RV32I.

---

## First coding-agent task

> Implement a synthesizable single-cycle RV32I processor.
>
> Implement modules independently:
>
> * program counter
> * instruction decoder
> * immediate generator
> * register file
> * ALU
> * branch comparator
> * control unit
> * load/store logic
>
> x0 must always remain zero.
>
> Memory interfaces must be explicit rather than embedded inside the CPU.
>
> Create directed testbenches for every instruction category.
>
> Do not implement pipelining yet.

---

# PHASE 3 — Verify the ISA

Before touching the pipeline, test:

```text
ADD/SUB
ALU ops
load/store
branch
jump
signed comparisons
unsigned comparisons
```

Add small assembly programs:

### Test 1

Sum:

```text
1 + 2 + ... + 100
```

Expected result:

```text
5050
```

### Test 2

Array sum.

### Test 3

Fibonacci.

### Test 4

Memory copy.

### Test 5

Sorting a tiny array.

If possible, integrate standard RISC-V architectural tests.

You want:

> RV32I architectural regression passing

before proceeding.

---

# PHASE 4 — Convert it into a 5-stage pipeline

Pipeline:

```text
IF → ID → EX → MEM → WB
```

Add pipeline registers:

```text
IF/ID
ID/EX
EX/MEM
MEM/WB
```

Each carries:

* data
* destination register
* control signals
* valid bit

---

# PHASE 5 — Hazard detection

Now deliberately create pipeline hazards.

Example:

```asm
ADD x1, x2, x3
SUB x4, x1, x5
```

Second instruction depends on first.

Implement:

### Forwarding

```text
EX/MEM → EX
MEM/WB → EX
```

### Load-use stall

```asm
LW  x1, 0(x2)
ADD x3, x1, x4
```

Requires a stall.

### Control hazards

Initially:

> branch resolved in EX

If taken:

```text
flush younger instructions
```

No branch predictor needed initially.

---

## Agent instruction

> Convert the verified single-cycle CPU into a classic five-stage pipeline.
>
> Add explicit pipeline registers and valid bits.
>
> Implement:
>
> * EX/MEM forwarding
> * MEM/WB forwarding
> * load-use hazard detection
> * pipeline stalls
> * branch/jump flushing
>
> Add assertions verifying that instructions killed by a flush cannot modify architectural state.
>
> Run all previously passing ISA tests against the pipelined implementation.

This last requirement is important.

---

# PHASE 6 — Performance counters

Add hardware counters:

```text
cycle_count
instruction_count
stall_count
branch_count
branch_taken_count
```

Calculate:

```text
IPC = retired instructions / cycles
CPI = cycles / retired instructions
```

Now you can benchmark architecture changes.

Good resume material.

---

# PHASE 7 — L1 instruction cache

Start easy.

Private instruction cache per core.

Suggested initial configuration:

```text
32-bit address
32-byte cache lines
direct mapped
1 KiB or 2 KiB
```

Implement:

```text
valid
tag
data
```

Operations:

```text
hit
miss
refill
```

Instruction caches can initially be read-only and do not need MESI complexity.

---

# PHASE 8 — L1 data cache

This is more important.

Start with:

```text
direct mapped
write-back
write-allocate
```

Each cache line:

```text
tag
data
valid
dirty
```

State machine roughly:

```text
IDLE
LOOKUP
WRITEBACK
REFILL
RESPOND
```

Test:

* read hit
* write hit
* read miss
* write miss
* dirty eviction
* clean eviction

Do not add coherence yet.

---

# PHASE 9 — Parameterize cache

Then make:

```text
CACHE_SIZE
LINE_SIZE
NUM_SETS
```

configurable.

Later you can benchmark:

```text
512 B
1 KiB
2 KiB
4 KiB
```

This gives an architectural evaluation angle.

---

# PHASE 10 — Replicate CPU

Only now instantiate:

```text
Core 0
Core 1
```

Each gets:

```text
private I$
private D$
```

Both share:

```text
main memory
```

At this point coherence is intentionally broken.

Create a test that demonstrates the bug.

Example:

```text
X initially = 0

Core 0 reads X → caches 0
Core 1 writes X = 7

Core 0 reads X again
```

Without coherence:

```text
Core 0 sees 0 ❌
```

This is an excellent demo because it establishes **why MESI is necessary**.

---

# PHASE 11 — Implement MESI

This is the centerpiece.

Each cache line has one of:

```text
M = Modified
E = Exclusive
S = Shared
I = Invalid
```

Conceptually:

### Modified

```text
only this cache owns copy
memory is stale
cache copy is dirty
```

### Exclusive

```text
only this cache owns copy
memory matches it
```

### Shared

```text
multiple caches may own copy
memory matches
```

### Invalid

```text
cache line unusable
```

---

# PHASE 12 — Coherence bus

Implement a simple snooping bus.

Possible bus transactions:

```text
BusRd
BusRdX
BusUpgr
Flush
```

Meaning roughly:

### BusRd

> I want to read this cache line.

### BusRdX

> I want this line exclusively because I'm writing it.

### BusUpgr

> I already have a shared copy; invalidate everyone else's.

---

# PHASE 13 — MESI FSM

Each D-cache line responds to:

* local processor read
* local processor write
* snooped BusRd
* snooped BusRdX
* snooped BusUpgr

Document every transition.

Example:

```text
I --CPU Read--> E/S
I --CPU Write--> M

S --CPU Write--> M
    + BusUpgr

E --CPU Write--> M

M --Other BusRd--> S
    + provide/write back data

M --Other BusRdX--> I
    + provide/write back data
```

The exact implementation needs to match your bus semantics consistently.

Do not let the agent casually invent transitions across modules.

Create **one canonical MESI transition specification** first.

---

# PHASE 14 — Agent task for MESI design

Before code:

> Design the MESI controller formally before implementing RTL.
>
> Produce a transition table containing:
>
> * current state
> * local event / snoop event
> * next state
> * bus action
> * memory action
> * processor response
>
> Include:
>
> * processor read
> * processor write
> * BusRd
> * BusRdX
> * BusUpgr
>
> Explicitly identify transient states required while waiting for bus/memory completion.
>
> Do not write RTL until this state machine has been documented.

Important: real implementations usually need more than the four stable states.

For example transient states like:

```text
IS
IM
SM
MI
```

may be useful.

That's good. It makes the project substantially more legitimate.

---

# PHASE 15 — Bus arbitration

Both cores may request bus ownership simultaneously.

Build arbiter.

Simplest:

```text
round-robin arbitration
```

Inputs:

```text
core0_request
core1_request
```

Outputs:

```text
grant0
grant1
```

Guarantee:

```text
never grant both simultaneously
```

Add assertion.

Potential later extension:

```text
N-core parameterized arbiter
```

---

# PHASE 16 — The crucial coherence tests

This should be extensive.

### Test A — Shared reads

```text
Core 0 reads X
Core 1 reads X
```

Expected:

```text
both eventually S
```

---

### Test B — Exclusive read

```text
Core 0 reads X
```

when nobody else has it.

Expected:

```text
Core 0 = E
```

---

### Test C — Exclusive → Modified

```text
Core 0 reads X
Core 0 writes X
```

Expected:

```text
E → M
```

No unnecessary bus transaction.

---

### Test D — Shared write

```text
Core 0 reads X
Core 1 reads X
Core 0 writes X
```

Expected:

```text
Core0: S → M
Core1: S → I
```

---

### Test E — Read modified copy

```text
Core 0 writes X
Core 1 reads X
```

Core 1 must receive latest value.

---

### Test F — Competing writes

```text
Core0 writes X
Core1 writes X
```

Ensure serialization.

---

### Test G — False sharing

Core 0 modifies:

```text
line offset 0
```

Core 1 modifies:

```text
same line, offset 4
```

Measure coherence traffic.

This is a fantastic benchmark topic.

---

# PHASE 17 — Assertions

This could distinguish the project massively.

Add SystemVerilog Assertions.

Critical invariant:

> At most one cache may hold a line in Modified state.

Formally conceptually:

```text
NOT (
    core0.X == Modified
    AND
    core1.X == Modified
)
```

Likewise:

> If one cache has E, the other must have I.

> If one cache has M, the other must have I.

> Both may hold S.

Also check:

* no two bus masters simultaneously
* x0 never changes
* pipeline flush cannot retire killed instruction
* cache responses correspond to valid outstanding request

This gives you a verification story, not just RTL.

---

# PHASE 18 — Randomized coherence verification

Build a software/reference memory model in the **testbench only**.

Generate random operations:

```text
Core0 READ A
Core1 WRITE B
Core0 WRITE C
Core1 READ A
...
```

After every relevant synchronization point, compare architectural memory results against reference behavior.

Generate:

```text
100 ops
1,000 ops
100,000 ops
```

with random addresses.

Bias some accesses to the same cache lines to stress coherence.

---

# PHASE 19 — Litmus tests

This is where it gets even more interesting.

Run small dual-core programs designed to expose shared-memory behavior.

Examples:

### Message passing

Core 0:

```c
data = 42;
flag = 1;
```

Core 1:

```c
while (!flag);
result = data;
```

Initially you can stay within a simple strongly ordered memory model.

Document that full RISC-V memory-model implementation is **outside V1** unless you explicitly implement it.

That honesty is important.

---

# PHASE 20 — Multicore software programs

Create programs where both cores actually do useful work.

Example:

## Parallel array sum

Core 0:

```text
sum first half
```

Core 1:

```text
sum second half
```

Combine.

Compare:

```text
single core cycles
dual core cycles
```

Calculate speedup.

---

## Producer-consumer

Core 0 writes items into shared buffer.

Core 1 consumes them.

Stress coherence.

---

## Shared counter

Both cores increment same memory location using a simple software protocol or later atomic extension.

This exposes contention.

---

# PHASE 21 — Optional but excellent: RV32A subset

After everything works, add selected atomic instructions:

```text
LR.W
SC.W
```

Potentially:

```text
AMOSWAP.W
AMOADD.W
```

This turns it from pure RV32I into:

> RV32I + selected A extension support.

That is **very relevant** to multicore architecture because now software can implement proper locks.

Then demo:

```text
spinlock
mutex
atomic counter
```

between the two cores.

I'd strongly consider this extension.

---

# PHASE 22 — Measure coherence behavior

Add hardware counters:

```text
l1_hits
l1_misses
writebacks

bus_rd
bus_rdx
bus_upgr

invalidations

mesi_M_cycles
mesi_E_cycles
mesi_S_cycles
mesi_I_cycles
```

Then benchmark programs.

Produce results like:

```text
Program          L1 miss rate    Invalidations    Bus traffic

array_sum            4.1%              12             87
shared_counter       8.7%             921           1204
false_sharing        5.3%            1821           2240
```

Do not fabricate numbers; generate them from simulation.

This transforms the repo from:

> “I built RTL”

into:

> “I evaluated an architecture.”

Excellent for IBM-style processor roles.

---

# PHASE 23 — Compare cache configurations

Run:

```text
512 B
1 KiB
2 KiB
4 KiB
```

Possibly:

```text
direct mapped
2-way set associative
```

Compare:

* hit rate
* cycles
* area
* timing

Now you get architecture tradeoffs.

---

# PHASE 24 — Verification coverage

If tooling permits, track:

* instruction coverage
* FSM state coverage
* MESI transition coverage
* cache hit/miss cases
* bus transaction cases

Create a matrix:

| Transition | Tested? |
| ---------- | ------: |
| I → E      |       ✓ |
| I → S      |       ✓ |
| I → M      |       ✓ |
| E → M      |       ✓ |
| E → S      |       ✓ |
| S → M      |       ✓ |
| S → I      |       ✓ |
| M → S      |       ✓ |
| M → I      |       ✓ |

This looks excellent in documentation.

---

# PHASE 25 — Synthesis

Now make it ASIC-relevant.

Use an open synthesis flow such as:

```text
Yosys
```

Target an available open standard-cell library.

Synthesize:

### Individually

```text
single core
D-cache
MESI controller
dual-core SoC
```

Report:

* cell count
* combinational area
* sequential area
* estimated frequency
* critical path

---

# PHASE 26 — Static timing analysis

Use OpenSTA or equivalent.

Determine:

```text
critical path
setup slack
max frequency
```

Likely candidates:

```text
ALU/forwarding path
cache tag comparison
coherence logic
```

Then optimize one real critical path.

This part is gold on a resume.

Instead of merely saying:

> synthesized design

you can say:

> identified X as the critical path and reduced logic depth / restructured arbitration to improve Fmax by Y%.

Only claim Y after measuring it.

---

# PHASE 27 — RTL-to-GDS

This is optional but strongly recommended for your specific hardware gap.

Run the full design, or at least a representative subsystem, through:

```text
RTL
 ↓
synthesis
 ↓
floorplanning
 ↓
placement
 ↓
clock-tree synthesis
 ↓
routing
 ↓
STA
 ↓
GDS
```

Using:

```text
OpenROAD/OpenLane
```

You do not need to pretend this makes you a physical-design expert.

The value is:

> you've actually seen the complete digital ASIC flow.

And the IBM JD explicitly spans physical design, processor chip development and VLSI flow. 

---

# PHASE 28 — Agent ASIC-flow prompt

> Take the verified RTL through an open-source synthesis and physical-design flow.
>
> Do not alter functionality to force tool success.
>
> Produce reproducible scripts for:
>
> * RTL synthesis
> * timing constraints
> * static timing analysis
> * floorplanning
> * placement
> * CTS
> * routing
>
> Record:
>
> * standard-cell area
> * utilization
> * worst negative slack
> * total negative slack
> * estimated Fmax
> * cell count
> * critical path
>
> Keep generated tool output separate from source RTL.
>
> Document all tool versions, constraints, assumptions and failures.

---

# PHASE 29 — Optional branch predictor

If you still have time:

Implement:

```text
2-bit saturating counter branch predictor
```

Potential BTB later.

Compare:

```text
always-not-taken
vs
2-bit predictor
```

Measure:

```text
branch accuracy
CPI
```

Nice architecture extension, but lower priority than coherence correctness.

---

# PHASE 30 — Optional 2-way cache

Upgrade:

```text
direct mapped
→
2-way set associative
```

Add:

```text
LRU replacement
```

Compare:

```text
miss rate
area
Fmax
```

Again, excellent tradeoff analysis.

---

# PHASE 31 — Don't accidentally make this impossible

For V1, explicitly exclude:

* Linux boot
* MMU
* virtual memory
* privilege modes
* full RV32A
* speculative execution
* out-of-order execution
* DRAM controller
* multicore >2
* complete RISC-V weak memory model

Those can become future work.

Your V1 is already ambitious.

---

# Definition of V1

I would not call the project complete until all of this works:

1. **Two synthesizable RV32I CPUs**
2. **Five-stage pipelines**
3. Forwarding
4. Stall detection
5. Branch flushes
6. Private I-caches
7. Private write-back D-caches
8. Shared memory
9. Bus arbitration
10. MESI coherence
11. Coherence assertions
12. Directed MESI tests
13. Randomized dual-core tests
14. At least 2 multicore benchmark programs
15. Architectural counters
16. Synthesis
17. Timing analysis
18. Documentation

That alone is an excellent project.

---

# What I'd call V2

Add:

* `LR/SC`
* AMO operations
* 2-way caches
* branch predictor
* more extensive assertions
* formal verification
* RTL-to-GDS
* performance/area exploration

---

# Formal verification — excellent stretch goal

This could make the project considerably more sophisticated.

Use something like SymbiYosys where feasible.

Try proving small invariants such as:

```text
never M/M
never M/E
never E/E
```

for the same line.

And arbiter:

```text
never grant0 && grant1
```

You don't need to formally prove the whole CPU.

Formal verification of **small critical properties** is enough to demonstrate exposure.

---

# Final project narrative

The repo should tell this story:

### Problem

Private multicore caches improve performance but introduce stale copies of shared memory.

### Solution

Designed a dual-core RV32I SoC with private L1 caches and a snooping MESI protocol maintaining cache coherence.

### Engineering

Built:

* pipelined processors
* forwarding/hazard logic
* write-back caches
* MESI state machines
* shared bus
* round-robin arbitration
* coherence verification
* performance counters

### Evaluation

Measured:

* cache hit rate
* coherence traffic
* CPI
* speedup
* contention
* false sharing
* synthesis area
* timing

That's a very strong processor-development story.

---

# What the coding agent must NOT do

This deserves explicit instruction.

Tell it:

> Do not pull an existing RISC-V core from GitHub and modify it.

> Do not instantiate PicoRV32, VexRiscv, Rocket, Ibex, CV32E40P or another pre-built CPU as the project core.

You can study established cores **for architectural reference**, but if the purpose is filling your RTL/design gap, the processor RTL needs to actually be yours.

Similarly:

> Do not use a pre-built cache coherence controller.

The value is specifically in designing and verifying it.

---

# How to use the agent without ending up unable to defend the project

Given what happened with your OS coursework, I would impose one additional rule:

**After every milestone, the agent must generate `docs/learning/<milestone>.md` containing:**

```text
What was built
Why it exists
Inputs/outputs
Important signals
FSM/datapath explanation
What could go wrong
Tests performed
5 likely interview questions
```

For example after MESI:

> Why is E different from S?

> Why is BusUpgr useful?

> When does M need to write back?

> Can both caches be S?

> Can both caches be M?

You read that before proceeding.

That way, when this eventually says:

> **Designed a dual-core cache-coherent RISC-V processor**

on your resume, you'll actually know what every major subsystem does.

---

