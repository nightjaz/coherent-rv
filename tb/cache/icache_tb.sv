`timescale 1ns/1ps
`default_nettype none
module icache_tb;
  localparam integer CS=512, LS=32;
  logic clk=0,rst_n=0,request,ready,memory_request,memory_ready;
  logic [31:0] address,read_data,memory_address;
  logic [LS*8-1:0] memory_read_line;
  logic [63:0] hits,misses;
  integer delay_count,i; logic pending;
  always #5 clk=~clk;
  icache #(.CACHE_SIZE(CS),.LINE_SIZE(LS)) dut(
    .clk,.rst_n,.cpu_request(request),.cpu_address(address),.cpu_read_data(read_data),.cpu_ready(ready),
    .memory_request,.memory_address,.memory_read_line,.memory_ready,.hit_count(hits),.miss_count(misses));
  always_ff @(posedge clk) begin
    memory_ready<=0;
    if(memory_request&&!pending)begin pending<=1;delay_count<=2;end
    else if(pending&&delay_count!=0)delay_count<=delay_count-1;
    else if(pending)begin
      for(i=0;i<LS/4;i=i+1)memory_read_line[i*32 +:32]<=memory_address+i*4+32'h1000;
      memory_ready<=1;pending<=0;
    end
  end
  task automatic fetch(input logic[31:0]a,input logic[31:0]expected);
    begin @(negedge clk);address=a;request=1;do @(posedge clk);while(!ready);#1;
      if(read_data!==expected)$fatal(1,"fetch %x got %x expected %x",a,read_data,expected);
      @(negedge clk);request=0;end
  endtask
  initial begin request=0;address=0;memory_ready=0;memory_read_line=0;pending=0;delay_count=0;
    repeat(3)@(posedge clk);rst_n<=1;
    fetch(32'h10,32'h1010);if(hits!=0||misses!=1)$fatal(1,"first access counters");
    fetch(32'h10,32'h1010);if(hits!=1||misses!=1)$fatal(1,"hit counters");
    fetch(32'h10+CS,32'h1010+CS);if(misses!=2)$fatal(1,"conflict miss absent");
    fetch(32'h10,32'h1010);if(misses!=3)$fatal(1,"conflict did not evict");
    $display("PASS icache first-miss refill hit conflict hits=%0d misses=%0d",hits,misses);$finish;
  end
endmodule
`default_nettype wire
