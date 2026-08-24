read_liberty physical/lib/NangateOpenCellLibrary_typical.lib
read_verilog build/mesi_controller_mapped.v
link_design mesi_controller
create_clock -name virtual_clk -period 10.000
set_input_delay 0.200 -clock virtual_clk [all_inputs]
set_output_delay 0.200 -clock virtual_clk [all_outputs]
report_checks -path_delay max -digits 4 -group_path_count 5
report_worst_slack -max
exit
