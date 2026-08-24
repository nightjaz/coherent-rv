SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
BUILD := build
CORE_RTL := rtl/core/alu.sv rtl/core/immediate_gen.sv rtl/core/control_unit.sv \
	rtl/core/register_file.sv rtl/core/hazard_unit.sv rtl/core/forwarding_unit.sv rtl/core/rv32_core.sv
SINGLE_RTL := rtl/core/alu.sv rtl/core/immediate_gen.sv rtl/core/control_unit.sv \
	rtl/core/register_file.sv rtl/core/program_counter.sv rtl/core/branch_comparator.sv \
	rtl/core/load_store_unit.sv rtl/core/rv32_single_cycle.sv
CACHE_RTL := rtl/cache/mesi_controller.sv rtl/cache/dcache.sv rtl/cache/icache.sv \
	rtl/interconnect/bus_arbiter.sv rtl/interconnect/coherence_bus.sv rtl/memory/simple_memory.sv

.PHONY: all lint test test-core clean synth timing cache-sweep test-random-long results
all: lint test

$(BUILD):
	mkdir -p $(BUILD)

lint: | $(BUILD)
	verilator --lint-only --timing -Wall -Wno-MULTITOP -Wno-UNUSEDPARAM -Wno-UNUSEDSIGNAL rtl/core/*.sv \
		rtl/cache/*.sv rtl/interconnect/*.sv rtl/memory/*.sv rtl/soc/*.sv

test: test-single-cycle test-core test-isa test-programs test-cache test-interconnect test-coherence test-soc

test-cache: | $(BUILD)
	iverilog -g2012 -Wall -s icache_tb -o $(BUILD)/icache_tb rtl/cache/icache.sv tb/cache/icache_tb.sv
	vvp $(BUILD)/icache_tb
	iverilog -g2012 -Wall -s dcache_tb -o $(BUILD)/dcache_tb rtl/cache/mesi_controller.sv rtl/cache/dcache.sv tb/cache/dcache_tb.sv
	vvp $(BUILD)/dcache_tb

test-single-cycle: | $(BUILD)
	iverilog -g2012 -Wall -DSINGLE_CYCLE -s rv32_isa_tb -o $(BUILD)/rv32_single_cycle_tb $(SINGLE_RTL) tb/core/rv32_isa_tb.sv
	vvp $(BUILD)/rv32_single_cycle_tb

test-core: | $(BUILD)
	iverilog -g2012 -Wall -s rv32_core_tb -o $(BUILD)/rv32_core_tb $(CORE_RTL) tb/assertions/core_assertions.sv tb/core/rv32_core_tb.sv
	vvp $(BUILD)/rv32_core_tb
	iverilog -g2012 -Wall -s core_stall_counter_tb -o $(BUILD)/core_stall_counter_tb $(CORE_RTL) tb/core/core_stall_counter_tb.sv
	vvp $(BUILD)/core_stall_counter_tb

test-interconnect: | $(BUILD)
	iverilog -g2012 -Wall -s bus_arbiter_tb -o $(BUILD)/bus_arbiter_tb rtl/interconnect/bus_arbiter.sv tb/interconnect/bus_arbiter_tb.sv
	vvp $(BUILD)/bus_arbiter_tb
	iverilog -g2012 -Wall -s coherence_bus_delayed_tb -o $(BUILD)/coherence_bus_delayed_tb rtl/interconnect/bus_arbiter.sv rtl/interconnect/coherence_bus.sv tb/interconnect/coherence_bus_delayed_tb.sv
	vvp $(BUILD)/coherence_bus_delayed_tb

test-isa: | $(BUILD)
	iverilog -g2012 -Wall -s rv32_isa_tb -o $(BUILD)/rv32_isa_tb $(CORE_RTL) tb/core/rv32_isa_tb.sv
	vvp $(BUILD)/rv32_isa_tb

test-riscv-arch: | $(BUILD)
	iverilog -g2012 -Wall -s riscv_arch_tb -o $(BUILD)/riscv_arch_tb $(CORE_RTL) tb/core/riscv_arch_tb.sv
	./scripts/test_riscv_arch.sh

test-programs: | $(BUILD)
	./scripts/test_programs.sh

test-coherence: | $(BUILD)
	iverilog -g2012 -Wall -s noncoherent_stale_tb -o $(BUILD)/noncoherent_stale_tb rtl/cache/mesi_controller.sv rtl/cache/dcache.sv tb/coherence/noncoherent_stale_tb.sv
	vvp $(BUILD)/noncoherent_stale_tb
	iverilog -g2012 -Wall -s coherence_tb -o $(BUILD)/coherence_tb $(CACHE_RTL) tb/assertions/coherence_assertions.sv tb/assertions/cache_assertions.sv tb/coherence/coherence_tb.sv
	vvp $(BUILD)/coherence_tb | tee $(BUILD)/coherence.log

test-random-long: | $(BUILD)
	iverilog -g2012 -Wall -s coherence_tb -Pcoherence_tb.RANDOM_OPS=100000 -o $(BUILD)/coherence_long $(CACHE_RTL) tb/assertions/coherence_assertions.sv tb/assertions/cache_assertions.sv tb/coherence/coherence_tb.sv
	vvp $(BUILD)/coherence_long | tee $(BUILD)/coherence-long.log

test-random-matrix: | $(BUILD)
	@: > $(BUILD)/random-matrix.log
	@for ops in 100 1000 100000; do for seed in 1 305419896 3735928559; do \
	 iverilog -g2012 -Wall -s coherence_tb -Pcoherence_tb.RANDOM_OPS=$$ops -Pcoherence_tb.SEED=$$seed -o $(BUILD)/coherence_$${ops}_$${seed} $(CACHE_RTL) tb/assertions/coherence_assertions.sv tb/assertions/cache_assertions.sv tb/coherence/coherence_tb.sv && \
	 vvp $(BUILD)/coherence_$${ops}_$${seed} | tee -a $(BUILD)/random-matrix.log || exit 1; done; done

test-assertions: | $(BUILD)
	rm -rf /tmp/coherentrv_obj_core_sva /tmp/coherentrv_obj_core_stall_sva /tmp/coherentrv_obj_coh_sva
	verilator --binary --timing --assert -Wno-TIMESCALEMOD -DENABLE_SVA --top-module rv32_core_tb $(CORE_RTL) tb/assertions/core_assertions.sv tb/core/rv32_core_tb.sv -Mdir /tmp/coherentrv_obj_core_sva
	/tmp/coherentrv_obj_core_sva/Vrv32_core_tb
	verilator --binary --timing --assert -Wno-TIMESCALEMOD -DENABLE_SVA --top-module core_stall_counter_tb $(CORE_RTL) tb/core/core_stall_counter_tb.sv -Mdir /tmp/coherentrv_obj_core_stall_sva
	/tmp/coherentrv_obj_core_stall_sva/Vcore_stall_counter_tb
	verilator --binary --timing --assert -Wno-TIMESCALEMOD -Wno-PINMISSING -Wno-WIDTHEXPAND -DENABLE_SVA --top-module coherence_tb $(CACHE_RTL) tb/assertions/coherence_assertions.sv tb/assertions/cache_assertions.sv tb/coherence/coherence_tb.sv -Mdir /tmp/coherentrv_obj_coh_sva
	/tmp/coherentrv_obj_coh_sva/Vcoherence_tb

test-soc: | $(BUILD)
	iverilog -g2012 -Wall -s parallel_sum_tb -o $(BUILD)/parallel_sum_tb rtl/core/*.sv rtl/cache/*.sv rtl/interconnect/*.sv rtl/memory/*.sv rtl/soc/*.sv tb/soc/parallel_sum_tb.sv
	vvp $(BUILD)/parallel_sum_tb | tee $(BUILD)/parallel_sum.log
	iverilog -g2012 -Wall -s parallel_sum_tb -Pparallel_sum_tb.SINGLE_MODE=1 -o $(BUILD)/single_sum_tb rtl/core/*.sv rtl/cache/*.sv rtl/interconnect/*.sv rtl/memory/*.sv rtl/soc/*.sv tb/soc/parallel_sum_tb.sv
	vvp $(BUILD)/single_sum_tb | tee $(BUILD)/single_sum.log
	iverilog -g2012 -Wall -s producer_consumer_tb -o $(BUILD)/producer_consumer_tb rtl/core/*.sv rtl/cache/*.sv rtl/interconnect/*.sv rtl/memory/*.sv rtl/soc/*.sv tb/soc/producer_consumer_tb.sv
	vvp $(BUILD)/producer_consumer_tb | tee $(BUILD)/producer_consumer.log
	iverilog -g2012 -Wall -s shared_counter_tb -o $(BUILD)/shared_counter_tb rtl/core/*.sv rtl/cache/*.sv rtl/interconnect/*.sv rtl/memory/*.sv rtl/soc/*.sv tb/soc/shared_counter_tb.sv
	vvp $(BUILD)/shared_counter_tb | tee $(BUILD)/shared_counter.log

synth: | $(BUILD)
	yosys -q -s synthesis/synth_core.ys
	yosys -q -s synthesis/synth_dcache.ys
	yosys -q -s synthesis/synth_soc.ys
	./scripts/fetch_nangate45.sh
	yosys -q -s synthesis/map_core.ys
	yosys -q -s synthesis/map_dcache_logic.ys
	yosys -q -s synthesis/map_mesi.ys
	yosys -q -s synthesis/map_soc_logic.ys

timing: | $(BUILD)
	./scripts/sta.sh

cache-sweep: | $(BUILD)
	./scripts/cache_sweep.sh

cache-area-sweep: | $(BUILD)
	./scripts/cache_area_sweep.sh

optimization-evidence: | $(BUILD)
	./scripts/optimization_evidence.sh

results:
	python3 scripts/coverage.py
	python3 scripts/random_report.py
	python3 scripts/benchmark.py

v1-regression: lint test test-riscv-arch test-assertions test-random-long test-random-matrix cache-sweep synth optimization-evidence
	REUSE_MAPPED=1 $(MAKE) timing
	$(MAKE) cache-area-sweep results

clean:
	rm -rf build/*
