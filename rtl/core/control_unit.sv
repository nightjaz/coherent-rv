`default_nettype none
module control_unit (
    input  logic [31:0] instruction,
    output logic        uses_rs1,
    output logic        uses_rs2,
    output logic        reg_write,
    output logic        mem_read,
    output logic        mem_write,
    output logic [2:0]  mem_funct3,
    output logic [3:0]  alu_op,
    output logic [1:0]  op_a_sel,
    output logic [1:0]  op_b_sel,
    output logic [2:0]  branch_op,
    output logic        jump,
    output logic        jump_reg,
    output logic [1:0]  wb_sel,
    output logic [31:0] immediate,
    output logic        illegal
);
    localparam logic [6:0] OP=7'b0110011, OP_IMM=7'b0010011, LOAD=7'b0000011,
        STORE=7'b0100011, BRANCH=7'b1100011, JAL=7'b1101111,
        JALR=7'b1100111, LUI=7'b0110111, AUIPC=7'b0010111;
    logic [6:0] opcode, funct7;
    logic [2:0] funct3;
    logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;
    immediate_gen u_imm(.instruction(instruction), .imm_i, .imm_s, .imm_b, .imm_u, .imm_j);
    assign opcode = instruction[6:0];
    assign funct3 = instruction[14:12];
    assign funct7 = instruction[31:25];
    always_comb begin
        uses_rs1=0; uses_rs2=0; reg_write=0; mem_read=0; mem_write=0;
        mem_funct3=funct3; alu_op=0; op_a_sel=0; op_b_sel=0; branch_op=0;
        jump=0; jump_reg=0; wb_sel=0; immediate=0; illegal=0;
        case (opcode)
            OP: begin
                uses_rs1=1; uses_rs2=1; reg_write=1;
                case (funct3)
                    3'b000: alu_op = funct7[5] ? 4'd1 : 4'd0;
                    3'b001: alu_op = 4'd2;
                    3'b010: alu_op = 4'd3;
                    3'b011: alu_op = 4'd4;
                    3'b100: alu_op = 4'd5;
                    3'b101: alu_op = funct7[5] ? 4'd7 : 4'd6;
                    3'b110: alu_op = 4'd8;
                    3'b111: alu_op = 4'd9;
                    default: illegal=1;
                endcase
                if (funct7 != 7'b0000000 && !(funct7 == 7'b0100000 && (funct3==0 || funct3==5))) illegal=1;
            end
            OP_IMM: begin
                uses_rs1=1; reg_write=1; op_b_sel=1; immediate=imm_i;
                case (funct3)
                    3'b000: alu_op=4'd0;
                    3'b010: alu_op=4'd3;
                    3'b011: alu_op=4'd4;
                    3'b100: alu_op=4'd5;
                    3'b110: alu_op=4'd8;
                    3'b111: alu_op=4'd9;
                    3'b001: begin alu_op=4'd2; if (funct7 != 0) illegal=1; end
                    3'b101: begin alu_op=funct7[5] ? 4'd7 : 4'd6; if (funct7 != 0 && funct7 != 7'b0100000) illegal=1; end
                    default: illegal=1;
                endcase
            end
            LOAD: begin uses_rs1=1; reg_write=1; mem_read=1; op_b_sel=1; immediate=imm_i; wb_sel=1; if (funct3==3 || funct3==6 || funct3==7) illegal=1; end
            STORE: begin uses_rs1=1; uses_rs2=1; mem_write=1; op_b_sel=1; immediate=imm_s; if (funct3>2) illegal=1; end
            BRANCH: begin uses_rs1=1; uses_rs2=1; branch_op=funct3; immediate=imm_b; if (funct3==2 || funct3==3) illegal=1; end
            JAL: begin reg_write=1; jump=1; immediate=imm_j; wb_sel=2; end
            JALR: begin uses_rs1=1; reg_write=1; jump=1; jump_reg=1; immediate=imm_i; wb_sel=2; if (funct3 != 0) illegal=1; end
            LUI: begin reg_write=1; op_a_sel=2; op_b_sel=1; immediate=imm_u; end
            AUIPC: begin reg_write=1; op_a_sel=1; op_b_sel=1; immediate=imm_u; end
            default: illegal=1;
        endcase
    end
endmodule
`default_nettype wire
