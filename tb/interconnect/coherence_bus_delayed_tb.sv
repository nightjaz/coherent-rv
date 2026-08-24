`timescale 1ns/1ps
`default_nettype none
module coherence_bus_delayed_tb;
 localparam integer LS=32;
 logic clk=0,rst_n=0;always#5 clk=~clk;
 logic r0,r1,g0,g1,ready0,ready1,shared0,shared1;
 logic[1:0]cmd0,cmd1;logic[31:0]addr0,addr1;
 logic[LS*8-1:0]write0,write1,read0,read1;
 logic sv0,sv1;logic[1:0]sc0,sc1;logic[31:0]sa0,sa1;
 logic sh0=0,sh1=1,ss0=0,ss1=1;logic[LS*8-1:0]sl0='0,sl1={8{32'hcafe1000}};
 logic mr,mw;logic[31:0]ma;logic[LS*8-1:0]mwl,mrl='0;logic mready=0;logic[63:0]br,brx,bu;
 coherence_bus #(.LINE_SIZE(LS))dut(.clk,.rst_n,.request0(r0),.command0(cmd0),.address0(addr0),.write_line0(write0),.grant0(g0),.ready0,.shared0,.read_line0(read0),
  .request1(r1),.command1(cmd1),.address1(addr1),.write_line1(write1),.grant1(g1),.ready1,.shared1,.read_line1(read1),
  .snoop_valid0(sv0),.snoop_command0(sc0),.snoop_address0(sa0),.snoop_hit0(sh0),.snoop_supply0(ss0),.snoop_line0(sl0),
  .snoop_valid1(sv1),.snoop_command1(sc1),.snoop_address1(sa1),.snoop_hit1(sh1),.snoop_supply1(ss1),.snoop_line1(sl1),
  .memory_read(mr),.memory_write(mw),.memory_address(ma),.memory_write_line(mwl),.memory_read_line(mrl),.memory_ready(mready),
  .bus_rd_count(br),.bus_rdx_count(brx),.bus_upgr_count(bu));
 initial begin
  r0=0;r1=0;cmd0=0;cmd1=1;addr0=32'h100;addr1=32'h200;write0='0;write1='0;
  repeat(2)@(posedge clk);rst_n<=1;@(negedge clk);r0=1;r1=1;
  @(posedge clk);#1;if(!g0||g1||ma!==32'h100)$fatal(1,"initial arbitration wrong");
  @(negedge clk);addr0=32'hdead0000;cmd0=2;sh1=0;ss1=0;sl1='0;
  repeat(4)begin @(posedge clk);#1;
   if(!g0||g1||ma!==32'h100||sv1||read0[31:0]!==32'hcafe1000||!mw||mwl[31:0]!==32'hcafe1000)$fatal(1,"dirty BusRd intervention not latched");
   if(ready0||ready1)$fatal(1,"early completion during delayed memory");
  end
  @(negedge clk);mready=1;#1;
  if(!ready0||ready1||ma!==32'h100||read0[31:0]!==32'hcafe1000)$fatal(1,"locked transaction completed with wrong dirty data");
  @(posedge clk);@(negedge clk);mready=0;r0=0;addr0=32'h100;sh0=1;ss0=1;sl0={8{32'hbeef2000}};
  @(posedge clk);#1;if(g0||!g1||ma!==32'h200)$fatal(1,"waiting requester did not acquire after completion");
  @(negedge clk);sh0=0;ss0=0;sl0='0;
  repeat(2)begin @(posedge clk);#1;if(read1[31:0]!==32'hbeef2000||sv0)$fatal(1,"dirty BusRdX intervention not latched");end
  @(negedge clk);mready=1;#1;if(!ready1||read1[31:0]!==32'hbeef2000)$fatal(1,"second requester failed dirty completion");
  @(posedge clk);#1;
  if(br!==1||brx!==1)$fatal(1,"transaction counters wrong rd=%0d rdx=%0d",br,brx);
  $display("PASS coherence bus locks owner, command, and address across delayed memory");$finish;
 end
endmodule
`default_nettype wire
