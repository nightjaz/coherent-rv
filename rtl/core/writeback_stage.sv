`default_nettype none
module writeback_stage(input logic [31:0] alu_data, memory_data, pc_plus_four,
    input logic [1:0] select, output logic [31:0] writeback_data);
    always_comb case(select) 1:writeback_data=memory_data; 2:writeback_data=pc_plus_four; default:writeback_data=alu_data; endcase
endmodule
`default_nettype wire
