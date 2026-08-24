`timescale 1ns/1ps
`default_nettype none
module rv32_isa_tb;
 logic clk=0,rst_n=0;always#5 clk=~clk;logic irq,iready=1,drq,dwr,dready=1;logic[31:0]ia,id,da,dwd,drd;logic[3:0]be;
 logic[63:0]cy,ins,st,bc,bt;logic rv,ill;logic[31:0]rp,ri;logic[31:0]rom[0:255];logic[7:0]ram[0:1023];integer i;
`ifdef SINGLE_CYCLE
 rv32_single_cycle dut(.clk,.rst_n,.imem_request(irq),.imem_address(ia),.imem_read_data(id),.imem_ready(iready),.dmem_request(drq),.dmem_write(dwr),.dmem_address(da),.dmem_write_data(dwd),.dmem_byte_enable(be),.dmem_read_data(drd),.dmem_ready(dready),.retired_valid(rv),.retired_pc(rp),.retired_instruction(ri),.illegal_instruction(ill));
`else
 rv32_core dut(.clk,.rst_n,.imem_request(irq),.imem_address(ia),.imem_read_data(id),.imem_ready(iready),.dmem_request(drq),.dmem_write(dwr),.dmem_address(da),.dmem_write_data(dwd),.dmem_byte_enable(be),.dmem_read_data(drd),.dmem_ready(dready),.cycle_count(cy),.instruction_count(ins),.stall_count(st),.branch_count(bc),.branch_taken_count(bt),.retired_valid(rv),.retired_pc(rp),.retired_instruction(ri),.illegal_instruction(ill));
`endif
 always_comb begin id=rom[ia[9:2]];drd={ram[{da[9:2],2'b0}+3],ram[{da[9:2],2'b0}+2],ram[{da[9:2],2'b0}+1],ram[{da[9:2],2'b0}]};end
 always_ff@(posedge clk)if(drq&&dwr)begin if(be[0])ram[{da[9:2],2'b0}]<=dwd[7:0];if(be[1])ram[{da[9:2],2'b0}+1]<=dwd[15:8];if(be[2])ram[{da[9:2],2'b0}+2]<=dwd[23:16];if(be[3])ram[{da[9:2],2'b0}+3]<=dwd[31:24];end
 always@(posedge clk)if(rst_n&&dut.u_registers.registers[0]!==0)$fatal(1,"x0 invariant");
 function automatic[31:0]I(input integer n,input[4:0]s,input[2:0]f,input[4:0]d,input[6:0]o);I={n[11:0],s,f,d,o};endfunction
 function automatic[31:0]R(input[6:0]f7,input[4:0]b,a,input[2:0]f,input[4:0]d);R={f7,b,a,f,d,7'b0110011};endfunction
 function automatic[31:0]S(input integer n,input[4:0]b,a,input[2:0]f);S={n[11:5],b,a,f,n[4:0],7'b0100011};endfunction
 function automatic[31:0]B(input integer n,input[4:0]b,a,input[2:0]f);B={n[12],n[10:5],b,a,f,n[4:1],n[11],7'b1100011};endfunction
 function automatic[31:0]U(input[19:0]n,input[4:0]d,input[6:0]o);U={n,d,o};endfunction
 function automatic[31:0]J(input integer n,input[4:0]d);J={n[20],n[10:1],n[11],n[19:12],d,7'b1101111};endfunction
 task automatic ck(input[4:0]r,input[31:0]v);if(dut.u_registers.registers[r]!==v)$fatal(1,"x%0d=%x expected=%x",r,dut.u_registers.registers[r],v);endtask
 initial begin
  for(i=0;i<256;i=i+1)rom[i]=32'h13;for(i=0;i<1024;i=i+1)ram[i]=0;
  rom[0]=I(-8,0,0,1,7'b0010011);rom[1]=I(3,0,0,2,7'b0010011);
  rom[2]=R(0,2,1,0,3);rom[3]=R(7'b0100000,2,1,0,4);rom[4]=R(0,2,1,7,5);rom[5]=R(0,2,1,6,6);rom[6]=R(0,2,1,4,7);
  rom[7]=R(0,2,2,1,8);rom[8]=R(0,2,1,2,9);rom[9]=R(0,2,1,3,10);rom[10]=R(0,2,1,5,11);rom[11]=R(7'b0100000,2,1,5,12);
  rom[12]=I(7,1,7,13,7'b0010011);rom[13]=I('h55,0,6,14,7'b0010011);rom[14]=I('hff,14,4,15,7'b0010011);
  rom[15]=I(4,2,1,16,7'b0010011);rom[16]=I(2,16,5,17,7'b0010011);rom[17]=I('h402,1,5,18,7'b0010011);
  rom[18]=I(-1,1,2,19,7'b0010011);rom[19]=I(4,2,3,20,7'b0010011);rom[20]=I('h100,0,0,21,7'b0010011);
  rom[21]=S(0,6,21,2);rom[22]=I(0,21,2,22,7'b0000011);rom[23]=S(4,14,21,0);rom[24]=I(4,21,0,23,7'b0000011);
  rom[25]=I(-1,0,0,14,7'b0010011);rom[26]=S(5,14,21,0);rom[27]=I(5,21,4,24,7'b0000011);rom[28]=I(5,21,0,25,7'b0000011);
  rom[29]=S(6,16,21,1);rom[30]=I(6,21,1,26,7'b0000011);rom[31]=I(6,21,5,27,7'b0000011);
  rom[32]=B(8,2,2,0);rom[33]=S(12,2,21,2);rom[34]=I(2,0,0,28,7'b0010011);
  rom[35]=B(8,2,1,1);rom[36]=I(1,0,0,29,7'b0010011);rom[37]=I(2,0,0,29,7'b0010011);
  rom[38]=B(8,2,1,4);rom[39]=I(1,0,0,30,7'b0010011);rom[40]=I(2,0,0,30,7'b0010011);
  rom[41]=B(8,1,2,5);rom[42]=I(3,0,0,30,7'b0010011);rom[43]=B(8,1,2,6);rom[44]=I(4,0,0,30,7'b0010011);
  rom[45]=B(8,2,1,7);rom[46]=I(5,0,0,30,7'b0010011);rom[47]=J(8,31);rom[48]=I(6,0,0,30,7'b0010011);
  rom[49]=U(0,5,7'b0010111);rom[50]=U('h12345,6,7'b0110111);rom[51]=I(212,0,0,7,7'b0010011);rom[52]=I(0,7,0,8,7'b1100111);
  rom[53]=S(8,30,21,2);rom[54]=32'h0000006f;
  repeat(3)@(posedge clk);rst_n<=1;
  repeat(800)begin @(posedge clk);if(ill)$fatal(1,"illegal at %x",rp);if({ram[267],ram[266],ram[265],ram[264]}==2)begin
    ck(3,32'hffff_fffb);ck(4,32'hffff_fff5);ck(6,32'h1234_5000);ck(7,212);ck(8,212);
    ck(9,1);ck(10,0);ck(11,32'h1fff_ffff);ck(12,32'hffff_ffff);ck(13,0);ck(15,32'h0000_00aa);
    ck(16,48);ck(17,12);ck(18,32'hffff_fffe);ck(19,1);ck(20,1);ck(22,32'hffff_fffb);
    ck(23,32'h55);ck(24,32'hff);ck(25,32'hffff_ffff);ck(26,48);ck(27,48);ck(28,2);ck(29,2);ck(30,2);ck(31,192);ck(5,196);
    if({ram[271],ram[270],ram[269],ram[268]}!==0)$fatal(1,"flushed store modified memory");
`ifdef SINGLE_CYCLE
    $display("PASS single-cycle RV32I categories");$finish;end end
`else
    $display("PASS pipelined RV32I categories retired=%0d branches=%0d taken=%0d",ins,bc,bt);$finish;end end
`endif
  $fatal(1,"ISA timeout sentinel=%x",{ram[267],ram[266],ram[265],ram[264]});
 end
endmodule
`default_nettype wire
