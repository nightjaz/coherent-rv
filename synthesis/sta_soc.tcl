read_liberty physical/lib/NangateOpenCellLibrary_typical.lib
read_verilog build/dual_core_soc_logic_mapped.v
link_design dual_core_soc
create_clock -name soc_clk -period 10.000 [get_ports clk]
set_input_delay 0.200 -clock soc_clk [all_inputs]
set_output_delay 0.200 -clock soc_clk [all_outputs]
set_false_path -from [get_ports rst_n]
report_checks -path_delay max -digits 4 -group_path_count 5
report_worst_slack -max
report_tns
exit
