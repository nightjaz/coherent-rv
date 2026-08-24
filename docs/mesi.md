# MESI protocol contract

CoherentRV uses a blocking, snooping MESI protocol. A bus transaction is atomic from grant through completion. The granted requester is the only bus master; all other D-caches snoop the address before completion. `BusRd` returns `shared=1` when another cache has a valid copy. Dirty intervention supplies the newest line. `BusRd` from Modified also updates memory before the line becomes Shared. `BusRdX` invalidates other copies and transfers dirty data directly when necessary. `BusUpgr` carries no data and is legal only for a local Shared hit.

Stable state encoding is `I=00`, `S=01`, `E=10`, `M=11`. The blocking-cache control states `IS`, `IM`, `SM`, and `MI` represent outstanding `BusRd`, `BusRdX`, `BusUpgr`, and dirty writeback respectively. Transients belong to the cache controller; tag state changes to the stable destination only when the bus completes.

| Current | Event | Next | Bus action | Memory/data action | CPU response |
|---|---|---|---|---|---|
| I | CPU read | IS → E/S | BusRd | Fill from intervention or memory; E if unshared, S if shared | Return requested word |
| I | CPU write | IM → M | BusRdX | Fill latest line, merge write | Acknowledge write |
| S | CPU read | S | none | Read local line | Return requested word |
| S | CPU write | SM → M | BusUpgr | Invalidate peers, merge write | Acknowledge write |
| E | CPU read | E | none | Read local line | Return requested word |
| E | CPU write | M | none | Merge write locally | Acknowledge write |
| M | CPU read/write | M | none | Read/merge local line | Return/acknowledge |
| S | snoop BusRd | S | none | Declare shared | none |
| E | snoop BusRd | S | intervene | Supply clean line, declare shared | none |
| M | snoop BusRd | S | Flush | Supply line and update memory | none |
| S/E | snoop BusRdX | I | invalidate | E may supply clean line | none |
| M | snoop BusRdX | I | Flush | Supply newest line | none |
| S | snoop BusUpgr | I | invalidate | none | none |
| I | any snoop | I | none | none | none |

Eviction of M performs `MI`/writeback before the replacement request. Clean S/E eviction becomes I without a transaction. Required global invariants are: never M/M, M implies peer I, E implies peer I, and never two simultaneous grants.

The implementation is strongly ordered because each core has at most one outstanding data request and the shared bus serializes coherence transactions. The complete RISC-V weak memory model is outside V1.
