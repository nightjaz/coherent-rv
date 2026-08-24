`default_nettype none
module fetch_stage(input logic [31:0] pc, output logic [31:0] next_pc);
    assign next_pc = pc + 32'd4;
endmodule
`default_nettype wire
