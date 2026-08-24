`timescale 1ns/1ps
`default_nettype none
module dcache_tb;
  localparam integer CS=512,LS=32;
  logic clk=0,rst_n=0,req,wr,ready,breq,bgrant,bready,bshared,svalid,shit,ssupply;
  logic[31:0]addr,wdata,rdata,baddr,saddr;logic[3:0]be;logic[1:0]bcmd,scmd;
  logic[LS*8-1:0]bwline,brline,sline;
  logic[63:0]hits,misses,wbs,invs,mc,ec,sc,ic;
  logic[LS*8-1:0]memory[0:63]; integer i; logic[63:0] before_count;
  always #5 clk=~clk;
  dcache #(.CACHE_SIZE(CS),.LINE_SIZE(LS)) dut(.*,.cpu_request(req),.cpu_write(wr),.cpu_address(addr),
    .cpu_write_data(wdata),.cpu_byte_enable(be),.cpu_read_data(rdata),.cpu_ready(ready),
    .bus_request(breq),.bus_command(bcmd),.bus_address(baddr),.bus_write_line(bwline),
    .bus_grant(bgrant),.bus_ready(bready),.bus_shared(bshared),.bus_read_line(brline),
    .snoop_valid(svalid),.snoop_command(scmd),.snoop_address(saddr),.snoop_hit(shit),
    .snoop_supply(ssupply),.snoop_line(sline),.hit_count(hits),.miss_count(misses),
    .writeback_count(wbs),.invalidation_count(invs),.mesi_m_cycles(mc),.mesi_e_cycles(ec),
    .mesi_s_cycles(sc),.mesi_i_cycles(ic));
  assign bgrant=breq;assign bready=breq;assign bshared=0;assign brline=memory[baddr[10:5]];
  always_ff @(posedge clk)if(breq&&bcmd==3)memory[baddr[10:5]]<=bwline;
  task automatic load(input[31:0]a,output[31:0]v);begin @(negedge clk);addr=a;wr=0;req=1;
    do @(posedge clk);while(!ready);#1;v=rdata;@(negedge clk);req=0;end endtask
  task automatic store(input[31:0]a,input[31:0]v,input[3:0]mask);begin @(negedge clk);addr=a;wdata=v;be=mask;wr=1;req=1;
    do @(posedge clk);while(!ready);#1;@(negedge clk);req=0;wr=0;end endtask
  initial begin req=0;wr=0;addr=0;wdata=0;be=15;svalid=0;scmd=0;saddr=0;
    for(i=0;i<64;i=i+1)memory[i]='0;memory[0][31:0]=32'h11223344;
    repeat(3)@(posedge clk);rst_n<=1;
    load(0,wdata);if(wdata!==32'h11223344||misses!=1||dut.states[0]!=2)$fatal(1,"read miss/refill/E");
    load(0,wdata);if(hits!=1)$fatal(1,"read hit");
    store(0,32'haabbccdd,4'b0011);load(0,wdata);if(wdata!==32'h1122ccdd||dut.states[0]!=3)$fatal(1,"write hit/byte enable/M");
    before_count=wbs;load(CS,wdata);if(wbs!=before_count+1||memory[0][31:0]!==32'h1122ccdd)$fatal(1,"dirty eviction/writeback");
    before_count=wbs;load(2*CS,wdata);if(wbs!=before_count)$fatal(1,"clean eviction wrote back");
    store(4,32'hdeadbeef,15);if(misses<4)$fatal(1,"write allocate miss not counted");
    $display("PASS dcache read-hit miss refill write-hit allocate clean/dirty-eviction counters h=%0d m=%0d wb=%0d",hits,misses,wbs);$finish;
  end
endmodule
`default_nettype wire
