`timescale 1ns/1ps
`default_nettype none
module parallel_sum_tb #(parameter integer SINGLE_MODE=0);
 logic clk=0,rst_n=0;always#5 clk=~clk;logic[63:0]c0cy,c0ret,c1cy,c1ret,br,brx,bu,hits,misses,wbs,invs,mc,ec,sc,ic;logic ill0,ill1;integer i;logic[31:0]final_word;
 dual_core_soc soc(.clk,.rst_n,.core0_cycles(c0cy),.core0_retired(c0ret),.core1_cycles(c1cy),.core1_retired(c1ret),.bus_rd_count(br),.bus_rdx_count(brx),.bus_upgr_count(bu),.l1_hits(hits),.l1_misses(misses),.writebacks(wbs),.invalidations(invs),.mesi_m_cycles(mc),.mesi_e_cycles(ec),.mesi_s_cycles(sc),.mesi_i_cycles(ic),.core0_illegal(ill0),.core1_illegal(ill1));
 function automatic[31:0]I(input integer n,input[4:0]s,input[2:0]f,input[4:0]d,input[6:0]o);I={n[11:0],s,f,d,o};endfunction
 function automatic[31:0]R(input[4:0]b,a,d);R={7'b0,b,a,3'b0,d,7'b0110011};endfunction
 function automatic[31:0]S(input integer n,input[4:0]b,a);S={n[11:5],b,a,3'b010,n[4:0],7'b0100011};endfunction
 function automatic[31:0]B(input integer n,input[4:0]b,a,input[2:0]f);B={n[12],n[10:5],b,a,f,n[4:1],n[11],7'b1100011};endfunction
 task automatic rom0(input integer n,input[31:0]v);soc.instruction_memory0.lines[n/8][(n%8)*32 +:32]=v;endtask
 task automatic rom1(input integer n,input[31:0]v);soc.instruction_memory1.lines[n/8][(n%8)*32 +:32]=v;endtask
 initial begin
  #1;
  for(i=0;i<8;i=i+1)soc.data_memory.lines[8][i*32 +:32]=i+1;
  if(SINGLE_MODE)begin
  rom0(0,I(256,0,0,1,7'b0010011));rom0(1,I(288,0,0,2,7'b0010011));rom0(2,I(0,0,0,3,7'b0010011));
  rom0(3,I(0,1,2,4,7'b0000011));rom0(4,R(4,3,3));rom0(5,I(4,1,0,1,7'b0010011));rom0(6,B(-12,2,1,4));
  rom0(7,I(512,0,0,5,7'b0010011));rom0(8,S(12,3,5));rom0(9,32'h0000006f);rom1(0,32'h0000006f);
  end else begin
  rom0(0,I(256,0,0,1,7'b0010011));rom0(1,I(272,0,0,2,7'b0010011));rom0(2,I(0,0,0,3,7'b0010011));
  rom0(3,I(0,1,2,4,7'b0000011));rom0(4,R(4,3,3));rom0(5,I(4,1,0,1,7'b0010011));rom0(6,B(-12,2,1,4));
  rom0(7,I(512,0,0,5,7'b0010011));rom0(8,S(0,3,5));rom0(9,I(8,5,2,7,7'b0000011));rom0(10,B(-4,0,7,0));
  rom0(11,I(4,5,2,6,7'b0000011));rom0(12,R(6,3,3));rom0(13,S(12,3,5));rom0(14,32'h0000006f);
  rom1(0,I(272,0,0,1,7'b0010011));rom1(1,I(288,0,0,2,7'b0010011));rom1(2,I(0,0,0,3,7'b0010011));
  rom1(3,I(0,1,2,4,7'b0000011));rom1(4,R(4,3,3));rom1(5,I(4,1,0,1,7'b0010011));rom1(6,B(-12,2,1,4));
  rom1(7,I(512,0,0,5,7'b0010011));rom1(8,S(4,3,5));rom1(9,I(1,0,0,6,7'b0010011));rom1(10,S(8,6,5));rom1(11,32'h0000006f);end
  repeat(3)@(posedge clk);rst_n<=1;
  repeat(5000)begin @(posedge clk);#1;if(ill0||ill1)$fatal(1,"illegal instruction");
    final_word=soc.dcache0.data[16][96 +:32];
    if(soc.dcache0.tags[16]==0&&soc.dcache0.states[16]!=0&&final_word==36)begin
      $display("PASS parallel_array_sum mode=%s result=36 c0_cycles=%0d c1_cycles=%0d c0_retired=%0d c1_retired=%0d BusRd=%0d BusRdX=%0d BusUpgr=%0d hits=%0d misses=%0d writebacks=%0d invalidations=%0d M=%0d E=%0d S=%0d I=%0d",SINGLE_MODE?"single":"dual",c0cy,c1cy,c0ret,c1ret,br,brx,bu,hits,misses,wbs,invs,mc,ec,sc,ic);$finish;end
  end
  $fatal(1,"parallel sum timeout c0x3=%0d c1x3=%0d c0x1=%0d c1x1=%0d state=%0d word=%0d",soc.core0.u_registers.registers[3],soc.core1.u_registers.registers[3],soc.core0.u_registers.registers[1],soc.core1.u_registers.registers[1],soc.dcache0.states[16],final_word);
 end
endmodule
`default_nettype wire
