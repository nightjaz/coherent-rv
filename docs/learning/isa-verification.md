# ISA verification checkpoint

## What was built
Directed instruction-category tests, five linked assembly programs, and an upstream RV32UI harness.
## Why it exists
Compilation alone cannot prove architectural behavior; independent expected results and pass signatures do.
## Inputs/outputs
ELF files become word hex images; retirement, registers, memory signatures, and upstream `ecall` pass codes are observed.
## Important signals
`retired_pc`, `retired_instruction`, `illegal_instruction`, register values, and byte-enabled stores are the main observability points.
## FSM/datapath explanation
The harness loads identical program/data images, runs until a pass/fail signature, and times out on nontermination.
## What could go wrong
An incorrect linker origin, false pass detection, endian mismatch, or using a reference core as the design.
## Tests performed
All five local programs and 37 official `riscv-tests` RV32UI cases pass.
## 5 likely interview questions
1. Why use upstream tests? 2. What is a signature? 3. How are illegal setup CSRs handled? 4. Why test byte loads? 5. What remains outside RV32I V1?
