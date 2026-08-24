# Generated verification coverage

Counts are emitted by transition instrumentation in `coherence_tb`; zero is a regression failure.

| MESI transition | Observed count | Covered |
|---|---:|:---:|
| I → E | 4 | ✓ |
| I → S | 309 | ✓ |
| I → M | 205 | ✓ |
| E → M | 1 | ✓ |
| E → S | 1 | ✓ |
| S → M | 305 | ✓ |
| S → I | 305 | ✓ |
| M → S | 308 | ✓ |
| M → I | 203 | ✓ |

Additional executable coverage: 37/37 upstream RV32UI files; arithmetic/logical/shift/compare/load/store/branch/jump/upper-immediate categories; cache first-hit/refill/conflict/clean-eviction/dirty-eviction/write-allocate; all four bus commands; sustained dual-request arbitration; false sharing; and 100 message-passing timing interleavings.
