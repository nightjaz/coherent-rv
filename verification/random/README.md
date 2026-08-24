# Random coherence regression

`make test-random-matrix` runs 100, 1,000, and 100,000-operation reference-model traces at three independent seeds. The trace biases sixteen words sharing two cache lines, so reads, writes, upgrades, invalidations, interventions, and false sharing recur. Every load is compared against the testbench-only reference memory.
