# CoherentRV architecture

CoherentRV is a synthesizable dual-core RV32I SoC. Each in-house core is a classic IF/ID/EX/MEM/WB pipeline with explicit valid bits, EX/MEM and MEM/WB forwarding, a one-cycle load-use bubble, and EX-stage branch/jump resolution. Killed IF/ID and ID/EX entries cannot retire. The external instruction and data interfaces use request/ready handshakes so cache misses back-pressure the pipeline.

Each core has a private, read-only direct-mapped instruction cache and a private, direct-mapped, write-back/write-allocate data cache. Cache dimensions are parameters. D-cache lines carry a MESI state; the shared snooping bus uses round-robin arbitration and executes BusRd, BusRdX, BusUpgr, and writeback transactions. A line memory is the point of persistence.

The implementation deliberately excludes privilege modes, MMU/virtual memory, Linux, speculation, out-of-order execution, DRAM, more than two cores, and the full weak memory model. These are not hidden assumptions: V1 is a small, strongly ordered educational SoC focused on pipeline and coherence correctness.

Module interfaces are documented next to their port declarations and in the subsystem documents. Generated simulation and synthesis artifacts live under `build/`; source RTL never depends on testbench models.

The exhaustive port-contract and FSM catalog is in `docs/interfaces.md`.
