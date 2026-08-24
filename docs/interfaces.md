# RTL interface and state-machine catalog

All design modules use active-low asynchronous reset where `rst_n` is present and synchronous request/ready completion at a rising `clk` edge. Testbench-only modules are excluded from this catalog.

| Module | Inputs | Outputs | Contract / state |
|---|---|---|---|
| `rv32_single_cycle` | clock/reset; instruction and data responses | explicit instruction/data requests; retirement | One instruction is held until required memory is ready. |
| `rv32_core` | clock/reset; instruction/data response and ready | instruction/data requests, byte enables, retirement, cycle/instruction/stall/branch counters | IF/ID, ID/EX, EX/MEM, MEM/WB valid registers; global memory back-pressure. |
| `program_counter` | clock/reset, enable, next PC | current PC | RESET/HOLD/ADVANCE register behavior. |
| `control_unit` | 32-bit instruction | decoded operand, ALU, memory, branch, writeback, illegal controls | Pure combinational RV32I decode. |
| `immediate_gen` | instruction | I/S/B/U/J immediate | Pure combinational sign extension/packing. |
| `register_file` | addresses, write port, clock/reset; `WRITE_THROUGH` parameter | two asynchronous read ports | x0 remains zero. The pipeline uses write-through reads; the single-cycle core disables them to avoid a combinational writeback loop. |
| `alu` | operands and operation | result | Combinational add/sub/shift/compare/logic. |
| `branch_comparator` | operands and branch operation | taken | Signed/unsigned combinational comparison. |
| `load_store_unit` | address, store data, function, memory word | byte enables, aligned store and extended load | Combinational SB/SH/SW and LB/LBU/LH/LHU/LW alignment. |
| `hazard_unit` | ID source usage and EX load destination | load-use stall | Combinational RAW detection. |
| `forwarding_unit` | EX sources and older destinations | operand selects | Priority is EX/MEM then MEM/WB; EX loads do not forward. |
| `fetch_stage`, `decode_stage`, `execute_stage`, `memory_stage`, `writeback_stage` | stage-local data/control | stage-local results | Named pedagogical stage helpers; integrated behavior is in `rv32_core`. |
| `icache` | CPU read request, refill line/ready | CPU word/ready, aligned refill request, hit/miss counters | `waiting=0` lookup; `waiting=1` refill. Blocking, direct-mapped, read-only. |
| `dcache` | CPU access, bus completion, snoop | CPU response; bus request; snoop hit/supply/line; counters | Control `IDLE`, `WRITEBACK`, `ACQUIRE`; each line has stable `I/S/E/M`. |
| `mesi_controller` | current state plus CPU/snoop event | next state and bus intent | Stable-state transition decoder instantiated by each D-cache snoop path. |
| `cache_controller` | cache request status | controller status | Compatibility helper; cache FSMs reside in I/D cache modules. |
| `bus_arbiter` | two request bits | one-hot grants | Round-robin `last_grant`; simultaneous sustained requests alternate. |
| `coherence_bus` | two master transactions, peer snoop results, memory response | grants/responses, snoops, memory transaction, bus counters | Locks owner, command, address, write data, and snoop response from selection through completion. |
| `memory_controller` | client transaction | memory-side transaction/response | Compatibility helper around explicit memory handshake. |
| `simple_memory` | line read/write command and address | line data and ready | Synchronous line array used as synthesizable SRAM model. |
| `dual_core_soc` | clock/reset | core/cache/bus/MESI counters and illegal status | Two private-cache cores, shared coherence bus, and shared data memory. |

## D-cache transient interpretation

`IDLE` contains stable hits. A dirty conflicting miss enters `WRITEBACK`; completion invalidates the victim and enters `ACQUIRE`. `ACQUIRE` represents IS for a read miss, IM for a write miss, or SM for a Shared write. A queued SM invalidated by a competing owner is upgraded to BusRdX before retry. A completing local store is forwarded onto a simultaneous snoop response so the peer cannot install stale data.

## Bus completion rule

Exactly one grant may be asserted. BusUpgr completes with its grant; read/ownership/writeback commands also require memory completion. A cache response therefore corresponds to a current hit or its recorded outstanding transaction. Assertions enforce recorded address stability; directed delayed-memory tests cover simultaneous requesters and dirty M→S/M→I intervention data retention.
