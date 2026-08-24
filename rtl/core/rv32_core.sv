`default_nettype none
module rv32_core #(
    parameter logic [31:0] RESET_PC = 32'h0000_0000
) (
    input  logic        clk,
    input  logic        rst_n,
    output logic        imem_request,
    output logic [31:0] imem_address,
    input  logic [31:0] imem_read_data,
    input  logic        imem_ready,
    output logic        dmem_request,
    output logic        dmem_write,
    output logic [31:0] dmem_address,
    output logic [31:0] dmem_write_data,
    output logic [3:0]  dmem_byte_enable,
    input  logic [31:0] dmem_read_data,
    input  logic        dmem_ready,
    output logic [63:0] cycle_count,
    output logic [63:0] instruction_count,
    output logic [63:0] stall_count,
    output logic [63:0] branch_count,
    output logic [63:0] branch_taken_count,
    output logic        retired_valid,
    output logic [31:0] retired_pc,
    output logic [31:0] retired_instruction,
    output logic        illegal_instruction
);
    typedef struct packed {logic valid; logic [31:0] pc, insn;} ifid_t;
    typedef struct packed {
        logic valid; logic [31:0] pc, insn, rs1_value, rs2_value, immediate;
        logic [4:0] rs1, rs2, rd; logic uses_rs1, uses_rs2, reg_write, mem_read, mem_write;
        logic [2:0] mem_funct3, branch_op; logic [3:0] alu_op;
        logic [1:0] op_a_sel, op_b_sel, wb_sel; logic jump, jump_reg, illegal;
    } idex_t;
    typedef struct packed {
        logic valid; logic [31:0] pc, insn, alu_result, store_value;
        logic [4:0] rd; logic reg_write, mem_read, mem_write;
        logic [2:0] mem_funct3; logic [1:0] wb_sel; logic illegal;
    } exmem_t;
    typedef struct packed {
        logic valid; logic [31:0] pc, insn, result; logic [4:0] rd;
        logic reg_write, illegal;
    } memwb_t;

    logic [31:0] fetch_pc;
    ifid_t ifid;
    idex_t idex;
    exmem_t exmem;
    memwb_t memwb;

    logic [4:0] dec_rs1, dec_rs2, dec_rd;
    logic [31:0] dec_rs1_value, dec_rs2_value, dec_immediate;
    logic dec_uses_rs1, dec_uses_rs2, dec_reg_write, dec_mem_read, dec_mem_write;
    logic [2:0] dec_mem_funct3, dec_branch_op;
    logic [3:0] dec_alu_op;
    logic [1:0] dec_op_a_sel, dec_op_b_sel, dec_wb_sel;
    logic dec_jump, dec_jump_reg, dec_illegal;
    logic wb_enable;
    logic load_use_stall, memory_stall;
    logic [1:0] forward_a_sel, forward_b_sel;
    logic [31:0] forwarded_a, forwarded_b, alu_a, alu_b, alu_result;
    logic branch_condition, redirect;
    logic [31:0] redirect_target, exmem_forward_value;
    logic [31:0] loaded_value, load_shifted, store_aligned;
    logic [3:0] store_be;
`ifndef SYNTHESIS
    logic [63:0] fetch_uid,ifid_uid,idex_uid,exmem_uid,memwb_uid,killed_uid;
    logic killed_uid_valid;
`endif

    assign dec_rs1 = ifid.insn[19:15];
    assign dec_rs2 = ifid.insn[24:20];
    assign dec_rd  = ifid.insn[11:7];
    control_unit u_control(
        .instruction(ifid.insn), .uses_rs1(dec_uses_rs1), .uses_rs2(dec_uses_rs2),
        .reg_write(dec_reg_write), .mem_read(dec_mem_read), .mem_write(dec_mem_write),
        .mem_funct3(dec_mem_funct3), .alu_op(dec_alu_op), .op_a_sel(dec_op_a_sel),
        .op_b_sel(dec_op_b_sel), .branch_op(dec_branch_op), .jump(dec_jump),
        .jump_reg(dec_jump_reg), .wb_sel(dec_wb_sel), .immediate(dec_immediate), .illegal(dec_illegal)
    );
    assign wb_enable = memwb.valid && memwb.reg_write && !memwb.illegal && !memory_stall;
    register_file u_registers(
        .clk, .rst_n, .rs1_addr(dec_rs1), .rs2_addr(dec_rs2),
        .rs1_data(dec_rs1_value), .rs2_data(dec_rs2_value),
        .write_enable(wb_enable), .write_addr(memwb.rd), .write_data(memwb.result)
    );
    hazard_unit u_hazard(
        .id_valid(ifid.valid), .id_uses_rs1(dec_uses_rs1), .id_uses_rs2(dec_uses_rs2),
        .id_rs1(dec_rs1), .id_rs2(dec_rs2), .ex_valid(idex.valid),
        .ex_is_load(idex.mem_read), .ex_rd(idex.rd), .load_use_stall
    );
    forwarding_unit u_forwarding(
        .rs1(idex.rs1), .rs2(idex.rs2),
        .exmem_valid(exmem.valid && !exmem.mem_read), .exmem_reg_write(exmem.reg_write), .exmem_rd(exmem.rd),
        .memwb_valid(memwb.valid), .memwb_reg_write(memwb.reg_write), .memwb_rd(memwb.rd),
        .forward_a(forward_a_sel), .forward_b(forward_b_sel)
    );
    assign exmem_forward_value = (exmem.wb_sel == 2) ? exmem.pc + 4 : exmem.alu_result;
    always_comb begin
        case (forward_a_sel)
            1: forwarded_a = exmem_forward_value;
            2: forwarded_a = memwb.result;
            default: forwarded_a = idex.rs1_value;
        endcase
        case (forward_b_sel)
            1: forwarded_b = exmem_forward_value;
            2: forwarded_b = memwb.result;
            default: forwarded_b = idex.rs2_value;
        endcase
        case (idex.op_a_sel)
            1: alu_a = idex.pc;
            2: alu_a = 0;
            default: alu_a = forwarded_a;
        endcase
        alu_b = idex.op_b_sel == 1 ? idex.immediate : forwarded_b;
    end
    alu u_alu(.a(alu_a), .b(alu_b), .op(idex.alu_op), .result(alu_result));

    always_comb begin
        case (idex.branch_op)
            3'b000: branch_condition = forwarded_a == forwarded_b;
            3'b001: branch_condition = forwarded_a != forwarded_b;
            3'b100: branch_condition = $signed(forwarded_a) < $signed(forwarded_b);
            3'b101: branch_condition = $signed(forwarded_a) >= $signed(forwarded_b);
            3'b110: branch_condition = forwarded_a < forwarded_b;
            3'b111: branch_condition = forwarded_a >= forwarded_b;
            default: branch_condition = 0;
        endcase
        redirect = idex.valid && (idex.jump || (idex.insn[6:0] == 7'b1100011 && branch_condition));
        redirect_target = idex.jump_reg ? ((forwarded_a + idex.immediate) & 32'hffff_fffe)
                                         : (idex.pc + idex.immediate);
    end

    always_comb begin
        store_be = 0; store_aligned = 0;
        case (exmem.mem_funct3)
            3'b000: begin store_be = 4'b0001 << exmem.alu_result[1:0]; store_aligned = exmem.store_value << (8*exmem.alu_result[1:0]); end
            3'b001: begin store_be = exmem.alu_result[1] ? 4'b1100 : 4'b0011; store_aligned = exmem.store_value << (16*exmem.alu_result[1]); end
            default: begin store_be = 4'b1111; store_aligned = exmem.store_value; end
        endcase
        load_shifted = dmem_read_data >> (8*exmem.alu_result[1:0]);
        case (exmem.mem_funct3)
            3'b000: loaded_value = {{24{load_shifted[7]}}, load_shifted[7:0]};
            3'b001: loaded_value = {{16{load_shifted[15]}}, load_shifted[15:0]};
            3'b100: loaded_value = {24'b0, load_shifted[7:0]};
            3'b101: loaded_value = {16'b0, load_shifted[15:0]};
            default: loaded_value = dmem_read_data;
        endcase
    end

    assign imem_request = rst_n;
    assign imem_address = fetch_pc;
    assign dmem_request = exmem.valid && (exmem.mem_read || exmem.mem_write);
    assign dmem_write = exmem.mem_write;
    assign dmem_address = exmem.alu_result;
    assign dmem_write_data = store_aligned;
    assign dmem_byte_enable = store_be;
    assign memory_stall = dmem_request && !dmem_ready;
    assign retired_valid = memwb.valid && !memory_stall;
    assign retired_pc = memwb.pc;
    assign retired_instruction = memwb.insn;
    assign illegal_instruction = memwb.valid && memwb.illegal && !memory_stall;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fetch_pc <= RESET_PC; ifid <= '0; idex <= '0; exmem <= '0; memwb <= '0;
            cycle_count <= 0; instruction_count <= 0; stall_count <= 0;
            branch_count <= 0; branch_taken_count <= 0;
`ifndef SYNTHESIS
            fetch_uid<=1;ifid_uid<=0;idex_uid<=0;exmem_uid<=0;memwb_uid<=0;killed_uid<=0;killed_uid_valid<=0;
`endif
        end else begin
            cycle_count <= cycle_count + 1;
            if (memwb.valid && !memory_stall) instruction_count <= instruction_count + 1;
            if (load_use_stall || memory_stall || !imem_ready) stall_count <= stall_count + 1;
            if (!memory_stall) begin
`ifndef SYNTHESIS
                memwb_uid<=exmem_uid;exmem_uid<=idex_uid;
`endif
                memwb.valid <= exmem.valid;
                memwb.pc <= exmem.pc; memwb.insn <= exmem.insn; memwb.rd <= exmem.rd;
                memwb.reg_write <= exmem.reg_write; memwb.illegal <= exmem.illegal;
                if (exmem.mem_read) memwb.result <= loaded_value;
                else if (exmem.wb_sel == 2) memwb.result <= exmem.pc + 4;
                else memwb.result <= exmem.alu_result;

                exmem.valid <= idex.valid; exmem.pc <= idex.pc; exmem.insn <= idex.insn;
                exmem.alu_result <= alu_result; exmem.store_value <= forwarded_b; exmem.rd <= idex.rd;
                exmem.reg_write <= idex.reg_write; exmem.mem_read <= idex.mem_read;
                exmem.mem_write <= idex.mem_write; exmem.mem_funct3 <= idex.mem_funct3;
                exmem.wb_sel <= idex.wb_sel; exmem.illegal <= idex.illegal;

                if (idex.valid && idex.insn[6:0] == 7'b1100011) begin
                    branch_count <= branch_count + 1;
                    if (branch_condition) branch_taken_count <= branch_taken_count + 1;
                end
                if (redirect) begin
                    fetch_pc <= redirect_target; ifid.valid <= 0; idex.valid <= 0;
`ifndef SYNTHESIS
                    if(ifid.valid)begin killed_uid<=ifid_uid;killed_uid_valid<=1;end
`endif
                end else if (load_use_stall) begin
                    idex.valid <= 0;
                end else begin
`ifndef SYNTHESIS
                    idex_uid<=ifid_uid;
`endif
                    idex.valid <= ifid.valid; idex.pc <= ifid.pc; idex.insn <= ifid.insn;
                    idex.rs1_value <= dec_rs1_value; idex.rs2_value <= dec_rs2_value;
                    idex.rs1 <= dec_rs1; idex.rs2 <= dec_rs2; idex.rd <= dec_rd;
                    idex.uses_rs1 <= dec_uses_rs1; idex.uses_rs2 <= dec_uses_rs2;
                    idex.immediate <= dec_immediate; idex.reg_write <= dec_reg_write;
                    idex.mem_read <= dec_mem_read; idex.mem_write <= dec_mem_write;
                    idex.mem_funct3 <= dec_mem_funct3; idex.alu_op <= dec_alu_op;
                    idex.op_a_sel <= dec_op_a_sel; idex.op_b_sel <= dec_op_b_sel;
                    idex.branch_op <= dec_branch_op; idex.jump <= dec_jump;
                    idex.jump_reg <= dec_jump_reg; idex.wb_sel <= dec_wb_sel; idex.illegal <= dec_illegal;
                    if (imem_ready) begin
                        ifid.valid <= 1; ifid.pc <= fetch_pc; ifid.insn <= imem_read_data;
                        fetch_pc <= fetch_pc + 4;
`ifndef SYNTHESIS
                        ifid_uid<=fetch_uid;fetch_uid<=fetch_uid+1;
`endif
                    end else ifid.valid <= 0;
                end
            end
        end
    end
endmodule
`default_nettype wire
