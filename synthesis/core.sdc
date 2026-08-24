create_clock -name core_clk -period 10.000 [get_ports clk]
set_input_delay 0.200 -clock core_clk [get_ports {imem_read_data imem_ready dmem_read_data dmem_ready}]
set_false_path -from [get_ports rst_n]
set_output_delay 0.200 -clock core_clk [all_outputs]
