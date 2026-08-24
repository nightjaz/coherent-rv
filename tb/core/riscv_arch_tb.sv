`timescale 1ns/1ps
`default_nettype none
module riscv_arch_tb;
  logic clk=0,rst_n=0,ir,dr,dw,rv,ill;logic[31:0]ia,id,da,dwd,drd,rpc,rinsn;logic[3:0]be;
  logic[63:0]cyc,ret,st,br,bt;logic[31:0]words[0:4095];logic[7:0]bytes[0:16383];
  string image;integer i,timeout_cycles;
  always #5 clk=~clk;
  rv32_core dut(.clk,.rst_n,.imem_request(ir),.imem_address(ia),.imem_read_data(id),.imem_ready(1'b1),
    .dmem_request(dr),.dmem_write(dw),.dmem_address(da),.dmem_write_data(dwd),.dmem_byte_enable(be),
    .dmem_read_data(drd),.dmem_ready(1'b1),.cycle_count(cyc),.instruction_count(ret),.stall_count(st),
    .branch_count(br),.branch_taken_count(bt),.retired_valid(rv),.retired_pc(rpc),.retired_instruction(rinsn),.illegal_instruction(ill));
  assign id=words[ia[13:2]];
  assign drd={bytes[{da[13:2],2'b0}+3],bytes[{da[13:2],2'b0}+2],bytes[{da[13:2],2'b0}+1],bytes[{da[13:2],2'b0}]};
  always_ff @(posedge clk)if(dr&&dw)begin
    if(be[0])bytes[{da[13:2],2'b0}]<=dwd[7:0];if(be[1])bytes[{da[13:2],2'b0}+1]<=dwd[15:8];
    if(be[2])bytes[{da[13:2],2'b0}+2]<=dwd[23:16];if(be[3])bytes[{da[13:2],2'b0}+3]<=dwd[31:24];end
  initial begin
    if(!$value$plusargs("IMAGE=%s",image))$fatal(1,"+IMAGE required");
    for(i=0;i<4096;i=i+1)words[i]=32'h00000013;$readmemh(image,words);
    for(i=0;i<16384;i=i+1)bytes[i]=0;
    for(i=0;i<4096;i=i+1)begin bytes[i*4]=words[i][7:0];bytes[i*4+1]=words[i][15:8];bytes[i*4+2]=words[i][23:16];bytes[i*4+3]=words[i][31:24];end
    repeat(3)@(posedge clk);rst_n<=1;
    for(timeout_cycles=0;timeout_cycles<20000;timeout_cycles=timeout_cycles+1)begin @(posedge clk);#1;
      if(rv&&rinsn==32'h00000073)begin
        if(dut.u_registers.registers[3]===32'd1)begin $display("PASS riscv-arch %s cycles=%0d retired=%0d",image,cyc,ret);$finish;end
        else $fatal(1,"architectural test failed testnum=%0d pc=%x",dut.u_registers.registers[3],rpc);
      end
    end $fatal(1,"architectural test timeout pc=%x",ia);
  end
endmodule
`default_nettype wire
