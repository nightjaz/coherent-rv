`default_nettype none
module decode_stage(input logic [31:0] instruction, output logic [4:0] rs1, rs2, rd);
    assign rs1=instruction[19:15]; assign rs2=instruction[24:20]; assign rd=instruction[11:7];
endmodule
`default_nettype wire
