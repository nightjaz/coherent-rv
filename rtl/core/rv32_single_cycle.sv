`default_nettype none
module rv32_single_cycle #(
    parameter logic[31:0]RESET_PC=32'h0000_0000
)(
    input logic clk,input logic rst_n,
    output logic imem_request,output logic[31:0]imem_address,
    input logic[31:0]imem_read_data,input logic imem_ready,
    output logic dmem_request,output logic dmem_write,output logic[31:0]dmem_address,
    output logic[31:0]dmem_write_data,output logic[3:0]dmem_byte_enable,
    input logic[31:0]dmem_read_data,input logic dmem_ready,
    output logic retired_valid,output logic[31:0]retired_pc,
    output logic[31:0]retired_instruction,output logic illegal_instruction
);
    logic[31:0]pc,next_pc,rs1_data,rs2_data,immediate,alu_a,alu_b,alu_result;
    logic[31:0]load_value,store_aligned,writeback_data;
    logic[4:0]rs1,rs2,rd;logic uses_rs1,uses_rs2,reg_write,mem_read,mem_write;
    logic[2:0]mem_funct3,branch_op;logic[3:0]alu_op;logic[1:0]op_a_sel,op_b_sel,wb_sel;
    logic jump,jump_reg,illegal,branch_taken,is_branch,execute_ready,write_enable;
    assign rs1=imem_read_data[19:15];assign rs2=imem_read_data[24:20];assign rd=imem_read_data[11:7];
    program_counter #(.RESET_PC(RESET_PC)) u_pc(.clk,.rst_n,.enable(execute_ready),.next_pc,.pc);
    control_unit u_control(.instruction(imem_read_data),.uses_rs1,.uses_rs2,.reg_write,.mem_read,.mem_write,
      .mem_funct3,.alu_op,.op_a_sel,.op_b_sel,.branch_op,.jump,.jump_reg,.wb_sel,.immediate,.illegal);
    register_file #(.WRITE_THROUGH(1'b0)) u_registers(.clk,.rst_n,.rs1_addr(rs1),.rs2_addr(rs2),.rs1_data,.rs2_data,
      .write_enable,.write_addr(rd),.write_data(writeback_data));
    branch_comparator u_branch(.a(rs1_data),.b(rs2_data),.operation(branch_op),.taken(branch_taken));
    always_comb begin
        case(op_a_sel)1:alu_a=pc;2:alu_a=0;default:alu_a=rs1_data;endcase
        alu_b=op_b_sel==1?immediate:rs2_data;
    end
    alu u_alu(.a(alu_a),.b(alu_b),.op(alu_op),.result(alu_result));
    load_store_unit u_lsu(.address(alu_result),.funct3(mem_funct3),.store_value(rs2_data),
      .memory_read_data(dmem_read_data),.load_value,.store_aligned,.byte_enable(dmem_byte_enable));
    assign is_branch=imem_read_data[6:0]==7'b1100011;
    always_comb begin
        next_pc=pc+4;
        if(jump)next_pc=jump_reg?((rs1_data+immediate)&32'hffff_fffe):(pc+immediate);
        else if(is_branch&&branch_taken)next_pc=pc+immediate;
        case(wb_sel)1:writeback_data=load_value;2:writeback_data=pc+4;default:writeback_data=alu_result;endcase
    end
    assign imem_request=rst_n;assign imem_address=pc;
    assign dmem_request=rst_n&&imem_ready&&(mem_read||mem_write);
    assign dmem_write=mem_write;assign dmem_address=alu_result;assign dmem_write_data=store_aligned;
    assign execute_ready=rst_n&&imem_ready&&(!(mem_read||mem_write)||dmem_ready);
    assign write_enable=execute_ready&&reg_write&&!illegal;
    assign retired_valid=execute_ready;assign retired_pc=pc;assign retired_instruction=imem_read_data;
    assign illegal_instruction=execute_ready&&illegal;
endmodule
`default_nettype wire
