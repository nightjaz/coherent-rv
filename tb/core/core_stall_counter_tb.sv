`timescale 1ns/1ps
`default_nettype none
module core_stall_counter_tb;
  logic clk=0,rst_n=0,ir,iready=1,dr,dw,dready=1,rv,ill;always #5 clk=~clk;
  logic[31:0]ia,id,da,dwd,drd=0,rpc,rinsn;logic[3:0]be;logic[63:0]cyc,ret,st,br,bt;
  logic[31:0]imem[0:31];integer i,waits;logic[63:0]held_ret;logic holding,check_active,served;integer stores,accepted_redirects;
  rv32_core dut(.clk,.rst_n,.imem_request(ir),.imem_address(ia),.imem_read_data(id),.imem_ready(iready),
    .dmem_request(dr),.dmem_write(dw),.dmem_address(da),.dmem_write_data(dwd),.dmem_byte_enable(be),
    .dmem_read_data(drd),.dmem_ready(dready),.cycle_count(cyc),.instruction_count(ret),.stall_count(st),
    .branch_count(br),.branch_taken_count(bt),.retired_valid(rv),.retired_pc(rpc),.retired_instruction(rinsn),.illegal_instruction(ill));
  assign id=imem[ia[6:2]];
`ifdef ENABLE_SVA
  assert property(@(posedge clk) disable iff(!rst_n) dut.redirect&&!dut.memory_stall |=> !dut.ifid.valid&&!dut.idex.valid);
`endif
  always_ff @(posedge clk)begin
    if(!rst_n)begin waits<=0;holding<=0;check_active<=0;served<=0;stores<=0;accepted_redirects<=0;end
    else if(dut.redirect&&!dut.memory_stall)accepted_redirects<=accepted_redirects+1;
    else if(!dr)served<=0;
    else if(dr&&!holding&&!served)begin dready<=0;waits<=5;holding<=1;check_active<=0;end
    else if(holding&&waits>0)begin
      waits<=waits-1;if(!check_active)begin held_ret<=ret;check_active<=1;end
      else if(ret!==held_ret)$fatal(1,"retirement repeated during memory stall");
    end else if(holding)begin dready<=1;holding<=0;served<=1;if(dw)stores<=stores+1;end
  end
  initial begin for(i=0;i<32;i=i+1)imem[i]=32'h00000013;
    imem[0]=32'h02a00093;imem[1]=32'h00102023;imem[2]=32'h00002103;imem[3]=32'h0000006f;
    repeat(3)@(posedge clk);rst_n<=1;repeat(80)@(posedge clk);
    if(dut.u_registers.registers[2]!==0||st<5||accepted_redirects==0)$fatal(1,"stall test x2=%x stalls=%0d redirects=%0d",dut.u_registers.registers[2],st,accepted_redirects);
    $display("PASS core stall counters retired=%0d stalls=%0d (no repeated retirement)",ret,st);$finish;
  end
endmodule
`default_nettype wire
