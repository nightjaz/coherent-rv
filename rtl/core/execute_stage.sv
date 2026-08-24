`default_nettype none
module execute_stage(input logic [31:0] a,b, input logic [3:0] operation, output logic [31:0] result);
    alu u_alu(.a, .b, .op(operation), .result);
endmodule
`default_nettype wire
