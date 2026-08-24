# CoherentRV

CoherentRV is an in-house, synthesizable dual-core RV32I SoC with five-stage pipelines, private parameterized L1 instruction/data caches, a snooping MESI protocol, round-robin arbitration, shared memory, architectural/coherence counters, randomized verification, and an open ASIC synthesis/timing flow.

The complete user-provided build specification is preserved verbatim in [SPEC.md](SPEC.md). The repository provides a reproducible V1 completion gate; items explicitly labeled optional/V2—RV32A, branch prediction, two-way caches, formal proofs, and RTL-to-GDS—are not claimed.

## Architecture

Each IF/ID/EX/MEM/WB pipeline implements the RV32I instruction categories, EX/MEM and MEM/WB forwarding, a load-use bubble, EX-stage redirects, and valid-bit flushes. Read-only I-caches and write-back/write-allocate D-caches are direct-mapped and parameterized. D-cache lines snoop atomic BusRd, BusRdX, BusUpgr, and writeback transactions. See [architecture](docs/architecture.md), [pipeline](docs/pipeline.md), [cache](docs/cache.md), and the canonical [MESI table](docs/mesi.md).

## Reproduce

Prerequisites are Verilator, Icarus Verilog, Yosys, Python 3, OpenSTA, and a `riscv64-elf-gcc`/binutils toolchain for linked programs and upstream architectural tests.

```sh
make lint
make test
make test-random-long
make cache-sweep
make synth
make timing
make results
# or the complete release gate:
make v1-regression
```

`make timing` fetches a commit-pinned Nangate45 Liberty file and uses `OPENSTA_BIN` when set, otherwise the locally installed path documented in `scripts/sta.sh`. Generated artifacts stay under `build/`; the downloaded library stays under `physical/lib/`. Neither is committed.

## Evidence

The release gate covers both CPU implementations, five local linked programs, 37 official upstream RV32UI tests, every stable MESI transition, executable SVA, cache/arbiter unit suites, multiple random lengths and seeds, 100 message-passing interleavings, three multicore workloads, false-sharing measurement, unified cache performance/area/timing sweeps, synthesis, and STA. See the [coverage matrix](verification/coverage/coverage.md), [verification plan](docs/verification.md), and generated [measured results](docs/results.md).

## Limitations

V1 is strongly ordered and blocking, with one outstanding data operation per core. It has no privilege modes, CSRs, traps beyond an illegal-instruction output, MMU, weak-memory implementation, atomics, speculation, OS boot, DRAM, or signoff physical design. These boundaries are deliberate and visible.
