# Pipeline

`rv32_core` implements IF → ID → EX → MEM → WB. IF/ID, ID/EX, EX/MEM, and MEM/WB are explicit packed registers containing a valid bit and all downstream data/control. The register file is write-first to close the WB-to-ID same-cycle dependency. EX operands select the youngest match, EX/MEM before MEM/WB. Loads are excluded from EX/MEM forwarding and trigger a load-use bubble. Data-memory back-pressure freezes every younger stage. A taken branch or jump redirects the fetch PC and clears IF/ID and ID/EX.

Counters record cycles, retired instructions, stalls, branches, and taken branches. IPC and CPI are calculated by the benchmark script rather than with division hardware.
