read_liberty physical/lib/NangateOpenCellLibrary_typical.lib
read_verilog $::env(DCACHE_NETLIST)
link_design dcache
create_clock -name cache_clk -period 10.000 [get_ports clk]
set_input_delay 0.200 -clock cache_clk [all_inputs]
set_output_delay 0.200 -clock cache_clk [all_outputs]
set_false_path -from [get_ports rst_n]
report_checks -path_delay max -digits 4 -group_path_count 1
report_worst_slack -max
exit
