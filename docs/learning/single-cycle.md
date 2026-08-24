# Single-cycle CPU checkpoint

## What was built
`rv32_single_cycle` executes the required RV32I integer subset with one architectural instruction in flight.
## Why it exists
It is the correctness baseline used before pipelining changes timing and introduces hazards.
## Inputs/outputs
Explicit request/ready instruction and data ports carry addresses, data, byte enables, and retirement status.
## Important signals
`pc`, `alu_result`, `branch_taken`, `dmem_request`, and `retired_valid` define the datapath transaction.
## FSM/datapath explanation
The PC feeds decode/register read, ALU/branch logic, optional data memory, writeback, then the next-PC register.
## What could go wrong
Bad immediate packing, x0 writes, signed comparison errors, or accepting an instruction before memory is ready.
## Tests performed
The complete category test covers arithmetic, logic, shifts, comparisons, loads/stores, all branches, JAL/JALR, LUI/AUIPC, and illegal decode.
## 5 likely interview questions
1. What limits its clock? 2. Why are memory ports explicit? 3. How is x0 protected? 4. How is JALR aligned? 5. Why build this before a pipeline?
