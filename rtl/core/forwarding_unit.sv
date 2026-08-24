`default_nettype none
module forwarding_unit (
    input logic [4:0] rs1, input logic [4:0] rs2,
    input logic exmem_valid, input logic exmem_reg_write, input logic [4:0] exmem_rd,
    input logic memwb_valid, input logic memwb_reg_write, input logic [4:0] memwb_rd,
    output logic [1:0] forward_a, output logic [1:0] forward_b
);
    always_comb begin
        forward_a=0; forward_b=0;
        if (memwb_valid && memwb_reg_write && memwb_rd!=0 && memwb_rd==rs1) forward_a=2;
        if (memwb_valid && memwb_reg_write && memwb_rd!=0 && memwb_rd==rs2) forward_b=2;
        if (exmem_valid && exmem_reg_write && exmem_rd!=0 && exmem_rd==rs1) forward_a=1;
        if (exmem_valid && exmem_reg_write && exmem_rd!=0 && exmem_rd==rs2) forward_b=1;
    end
endmodule
`default_nettype wire
