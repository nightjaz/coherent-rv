`timescale 1ns/1ps
`default_nettype none
module rv32_core_tb;
    logic clk=0, rst_n=0;
    always #5 clk=~clk;
    logic imem_request, imem_ready=1, dmem_request, dmem_write, dmem_ready=1;
    logic [31:0] imem_address, imem_read_data, dmem_address, dmem_write_data, dmem_read_data;
    logic [3:0] dmem_byte_enable;
    logic [63:0] cycles, instructions, stalls, branches, taken;
    logic retired_valid, illegal; logic [31:0] retired_pc, retired_insn;
    logic [31:0] imem [0:255]; logic [7:0] dmem [0:1023];
    integer i;
    rv32_core dut(
        .clk,.rst_n,.imem_request,.imem_address,.imem_read_data,.imem_ready,
        .dmem_request,.dmem_write,.dmem_address,.dmem_write_data,.dmem_byte_enable,
        .dmem_read_data,.dmem_ready,.cycle_count(cycles),.instruction_count(instructions),
        .stall_count(stalls),.branch_count(branches),.branch_taken_count(taken),
        .retired_valid,.retired_pc,.retired_instruction(retired_insn),.illegal_instruction(illegal)
    );
    core_assertions core_sva(.clk,.rst_n,.x0(dut.u_registers.registers[0]));
`ifdef ENABLE_SVA
    assert property(@(posedge clk) disable iff(!rst_n) dut.redirect&&!dut.memory_stall |=> !dut.ifid.valid && !dut.idex.valid);
    assert property(@(posedge clk) disable iff(!rst_n) retired_valid |-> !illegal);
    assert property(@(posedge clk) disable iff(!rst_n) (dut.killed_uid_valid&&retired_valid) |-> dut.memwb_uid!=dut.killed_uid);
    assert property(@(posedge clk) disable iff(!rst_n) (dut.killed_uid_valid&&dut.wb_enable) |-> dut.memwb_uid!=dut.killed_uid);
    assert property(@(posedge clk) disable iff(!rst_n) (dut.killed_uid_valid&&dmem_request&&dmem_write) |-> dut.exmem_uid!=dut.killed_uid);
`endif
    always_comb begin
        imem_read_data = imem[imem_address[9:2]];
        dmem_read_data = {dmem[{dmem_address[9:2],2'b00}+3], dmem[{dmem_address[9:2],2'b00}+2],
                          dmem[{dmem_address[9:2],2'b00}+1], dmem[{dmem_address[9:2],2'b00}]};
    end
    always_ff @(posedge clk) if (dmem_request && dmem_write) begin
        if(dmem_byte_enable[0]) dmem[{dmem_address[9:2],2'b00}]   <= dmem_write_data[7:0];
        if(dmem_byte_enable[1]) dmem[{dmem_address[9:2],2'b00}+1] <= dmem_write_data[15:8];
        if(dmem_byte_enable[2]) dmem[{dmem_address[9:2],2'b00}+2] <= dmem_write_data[23:16];
        if(dmem_byte_enable[3]) dmem[{dmem_address[9:2],2'b00}+3] <= dmem_write_data[31:24];
    end
    always @(posedge clk) if(rst_n && dut.u_registers.registers[0] !== 0) $fatal(1,"x0 invariant");
    function automatic [31:0] enc_i(input integer imm,input [4:0] rs1,input [2:0] f3,input [4:0] rd,input [6:0] op);
        enc_i={imm[11:0],rs1,f3,rd,op};
    endfunction
    function automatic [31:0] enc_r(input [6:0] f7,input [4:0] rs2,input [4:0] rs1,input [2:0] f3,input [4:0] rd);
        enc_r={f7,rs2,rs1,f3,rd,7'b0110011};
    endfunction
    function automatic [31:0] enc_s(input integer imm,input [4:0] rs2,input [4:0] rs1,input [2:0] f3);
        enc_s={imm[11:5],rs2,rs1,f3,imm[4:0],7'b0100011};
    endfunction
    function automatic [31:0] enc_b(input integer imm,input [4:0] rs2,input [4:0] rs1,input [2:0] f3);
        enc_b={imm[12],imm[10:5],rs2,rs1,f3,imm[4:1],imm[11],7'b1100011};
    endfunction
    initial begin
        for(i=0;i<256;i=i+1) imem[i]=32'h00000013;
        for(i=0;i<1024;i=i+1) dmem[i]=0;
        imem[0]=enc_i(1,0,0,1,7'b0010011);       // x1=1
        imem[1]=enc_i(101,0,0,2,7'b0010011);     // x2=101
        imem[2]=enc_i(0,0,0,3,7'b0010011);       // sum=0
        imem[3]=enc_r(0,1,3,0,3);                // sum+=i
        imem[4]=enc_i(1,1,0,1,7'b0010011);       // i++
        imem[5]=enc_b(-8,2,1,3'b100);             // blt i,101,loop
        imem[6]=enc_s(0,3,0,3'b010);              // store sum
        imem[7]=32'h0000006f;                     // halt: jal x0,0
        repeat(3) @(posedge clk); rst_n<=1;
        repeat(1200) begin
            @(posedge clk);
            if (illegal) $fatal(1,"illegal instruction retired at %x",retired_pc);
            if ({dmem[3],dmem[2],dmem[1],dmem[0]} == 32'd5050) begin
                $display("PASS rv32 pipeline sum=5050 cycles=%0d retired=%0d stalls=%0d",cycles,instructions,stalls);
                break;
            end
        end
        if({dmem[3],dmem[2],dmem[1],dmem[0]}!=32'd5050)
            $fatal(1,"timeout sum=%0d x1=%0d x3=%0d",{dmem[3],dmem[2],dmem[1],dmem[0]},dut.u_registers.registers[1],dut.u_registers.registers[3]);
        $finish;
    end
endmodule
`default_nettype wire
