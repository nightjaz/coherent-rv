`default_nettype none
module hazard_unit (
    input logic id_valid,
    input logic id_uses_rs1,
    input logic id_uses_rs2,
    input logic [4:0] id_rs1,
    input logic [4:0] id_rs2,
    input logic ex_valid,
    input logic ex_is_load,
    input logic [4:0] ex_rd,
    output logic load_use_stall
);
    always_comb load_use_stall = id_valid && ex_valid && ex_is_load && ex_rd != 0 &&
        ((id_uses_rs1 && id_rs1 == ex_rd) || (id_uses_rs2 && id_rs2 == ex_rd));
endmodule
`default_nettype wire
