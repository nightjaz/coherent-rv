`timescale 1ns/1ps
`default_nettype none
module cache_capacity_tb #(parameter integer CACHE_SIZE=1024,parameter integer LINE_SIZE=32,parameter integer WORKING_BYTES=4096);
 logic clk=0,rst_n=0,req,ready,mreq,mready;logic[31:0]addr,rdata,maddr;logic[LINE_SIZE*8-1:0]mline;
 logic[63:0]hits,misses,cycles;integer i,pass,mem_i;
 always #5 clk=~clk;
 icache #(.CACHE_SIZE(CACHE_SIZE),.LINE_SIZE(LINE_SIZE))dut(.clk,.rst_n,.cpu_request(req),.cpu_address(addr),.cpu_read_data(rdata),.cpu_ready(ready),.memory_request(mreq),.memory_address(maddr),.memory_read_line(mline),.memory_ready(mready),.hit_count(hits),.miss_count(misses));
 always_comb begin mready=mreq;for(mem_i=0;mem_i<LINE_SIZE/4;mem_i=mem_i+1)mline[mem_i*32 +:32]=maddr+mem_i*4;end
 always_ff@(posedge clk)if(!rst_n)cycles<=0;else cycles<=cycles+1;
 task automatic fetch(input[31:0]a);begin @(negedge clk);addr=a;req=1;do @(posedge clk);while(!ready);#1;
   if(rdata!==a)$fatal(1,"capacity read %x got %x",a,rdata);@(negedge clk);req=0;end endtask
 initial begin req=0;addr=0;cycles=0;repeat(3)@(posedge clk);rst_n<=1;
  for(pass=0;pass<2;pass=pass+1)for(i=0;i<WORKING_BYTES;i=i+4)fetch(i);
  $display("PASS cache_capacity size=%0d line=%0d working=%0d cycles=%0d hits=%0d misses=%0d miss_rate_ppm=%0d",CACHE_SIZE,LINE_SIZE,WORKING_BYTES,cycles,hits,misses,misses*1000000/(hits+misses));$finish;end
endmodule
`default_nettype wire
