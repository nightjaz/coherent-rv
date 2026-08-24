read_liberty physical/lib/NangateOpenCellLibrary_typical.lib
read_verilog build/rv32_core_mapped.v
link_design rv32_core
read_sdc synthesis/core.sdc
report_checks -path_delay max -fields {slew cap input_pin} -digits 4 -group_path_count 5
report_worst_slack -max
report_tns
exit
