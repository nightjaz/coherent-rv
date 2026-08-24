`timescale 1ns/1ps
`default_nettype none
module producer_consumer_tb;
 logic clk=0,rst_n=0;always#5 clk=~clk;logic[63:0]c0cy,c0ret,c1cy,c1ret,br,brx,bu,hits,misses,wbs,invs,mc,ec,sc,ic;logic ill0,ill1;logic[31:0]result;
 dual_core_soc soc(.clk,.rst_n,.core0_cycles(c0cy),.core0_retired(c0ret),.core1_cycles(c1cy),.core1_retired(c1ret),.bus_rd_count(br),.bus_rdx_count(brx),.bus_upgr_count(bu),.l1_hits(hits),.l1_misses(misses),.writebacks(wbs),.invalidations(invs),.mesi_m_cycles(mc),.mesi_e_cycles(ec),.mesi_s_cycles(sc),.mesi_i_cycles(ic),.core0_illegal(ill0),.core1_illegal(ill1));
 function automatic[31:0]I(input integer n,input[4:0]s,input[2:0]f,input[4:0]d,input[6:0]o);I={n[11:0],s,f,d,o};endfunction
 function automatic[31:0]R(input[4:0]b,a,d);R={7'b0,b,a,3'b0,d,7'b0110011};endfunction
 function automatic[31:0]S(input integer n,input[4:0]b,a);S={n[11:5],b,a,3'b010,n[4:0],7'b0100011};endfunction
 function automatic[31:0]B(input integer n,input[4:0]b,a,input[2:0]f);B={n[12],n[10:5],b,a,f,n[4:1],n[11],7'b1100011};endfunction
 task automatic rom0(input integer n,input[31:0]v);soc.instruction_memory0.lines[n/8][(n%8)*32 +:32]=v;endtask
 task automatic rom1(input integer n,input[31:0]v);soc.instruction_memory1.lines[n/8][(n%8)*32 +:32]=v;endtask
 initial begin #1;
  rom0(0,I(768,0,0,1,7'b0010011));rom0(1,I(10,0,0,2,7'b0010011));rom0(2,S(0,2,1));
  rom0(3,I(20,0,0,2,7'b0010011));rom0(4,S(4,2,1));rom0(5,I(30,0,0,2,7'b0010011));rom0(6,S(8,2,1));
  rom0(7,I(1,0,0,2,7'b0010011));rom0(8,S(12,2,1));rom0(9,32'h0000006f);
  rom1(0,I(768,0,0,1,7'b0010011));rom1(1,I(12,1,2,2,7'b0000011));rom1(2,B(-4,0,2,0));
  rom1(3,I(0,1,2,3,7'b0000011));rom1(4,I(4,1,2,4,7'b0000011));rom1(5,R(4,3,3));
  rom1(6,I(8,1,2,4,7'b0000011));rom1(7,R(4,3,3));rom1(8,I(800,0,0,5,7'b0010011));rom1(9,S(0,3,5));rom1(10,32'h0000006f);
  repeat(3)@(posedge clk);rst_n<=1;
  repeat(3000)begin @(posedge clk);#1;if(ill0||ill1)$fatal(1,"illegal instruction");result=soc.dcache1.data[25][0+:32];
   if(soc.dcache1.tags[25]==0&&soc.dcache1.states[25]!=0&&result==60)begin
    $display("PASS producer_consumer result=60 c0_cycles=%0d c1_cycles=%0d c0_retired=%0d c1_retired=%0d BusRd=%0d BusRdX=%0d BusUpgr=%0d hits=%0d misses=%0d writebacks=%0d invalidations=%0d M=%0d E=%0d S=%0d I=%0d",c0cy,c1cy,c0ret,c1ret,br,brx,bu,hits,misses,wbs,invs,mc,ec,sc,ic);$finish;end
  end
  $fatal(1,"producer consumer timeout result=%0d x3=%0d",result,soc.core1.u_registers.registers[3]);
 end
endmodule
`default_nettype wire
