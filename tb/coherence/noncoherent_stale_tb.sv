`timescale 1ns/1ps
`default_nettype none
module noncoherent_stale_tb;
 localparam integer LS=32;logic clk=0,rst_n=0;always#5 clk=~clk;
 logic req0,wr0,ready0,breq0,req1,wr1,ready1,breq1;logic[31:0]a0,w0,r0,ba0,a1,w1,r1,ba1;logic[3:0]be0,be1;
 logic[1:0]bc0,bc1;logic[LS*8-1:0]bwl0,bwl1,line0,line1,zero='0;logic[63:0]u0,u1,u2,u3,u4,u5,u6,u7;
 logic[LS*8-1:0]memory[0:31];integer i;
 dcache c0(.clk,.rst_n,.cpu_request(req0),.cpu_write(wr0),.cpu_address(a0),.cpu_write_data(w0),.cpu_byte_enable(be0),.cpu_read_data(r0),.cpu_ready(ready0),.bus_request(breq0),.bus_command(bc0),.bus_address(ba0),.bus_write_line(bwl0),.bus_grant(breq0),.bus_ready(breq0),.bus_shared(1'b0),.bus_read_line(line0),.snoop_valid(1'b0),.snoop_command(2'b0),.snoop_address(32'b0),.snoop_hit(),.snoop_supply(),.snoop_line(),.hit_count(u0),.miss_count(u1),.writeback_count(u2),.invalidation_count(u3),.mesi_m_cycles(),.mesi_e_cycles(),.mesi_s_cycles(),.mesi_i_cycles());
 dcache c1(.clk,.rst_n,.cpu_request(req1),.cpu_write(wr1),.cpu_address(a1),.cpu_write_data(w1),.cpu_byte_enable(be1),.cpu_read_data(r1),.cpu_ready(ready1),.bus_request(breq1),.bus_command(bc1),.bus_address(ba1),.bus_write_line(bwl1),.bus_grant(breq1),.bus_ready(breq1),.bus_shared(1'b0),.bus_read_line(line1),.snoop_valid(1'b0),.snoop_command(2'b0),.snoop_address(32'b0),.snoop_hit(),.snoop_supply(),.snoop_line(),.hit_count(u4),.miss_count(u5),.writeback_count(u6),.invalidation_count(u7),.mesi_m_cycles(),.mesi_e_cycles(),.mesi_s_cycles(),.mesi_i_cycles());
 assign line0=memory[ba0[9:5]];assign line1=memory[ba1[9:5]];
 always_ff@(posedge clk)begin if(breq0&&bc0==3)memory[ba0[9:5]]<=bwl0;if(breq1&&bc1==3)memory[ba1[9:5]]<=bwl1;end
 task automatic read0(output[31:0]v);begin @(negedge clk);req0=1;wr0=0;do@(posedge clk);while(!ready0);#1;v=r0;@(negedge clk);req0=0;end endtask
 task automatic write1(input[31:0]v);begin @(negedge clk);req1=1;wr1=1;w1=v;do@(posedge clk);while(!ready1);@(negedge clk);req1=0;wr1=0;end endtask
 initial begin req0=0;wr0=0;a0=0;w0=0;be0=15;req1=0;wr1=0;a1=0;w1=0;be1=15;for(i=0;i<32;i=i+1)memory[i]=0;
  repeat(3)@(posedge clk);rst_n<=1;read0(w0);write1(42);read0(w0);
  if(w0!==0||c0.states[0]!==2||c1.states[0]!==3)$fatal(1,"stale demonstration did not reproduce");
  $display("PASS pre-MESI stale-cache demonstration core0=%0d core1_new=42 memory=%0d",w0,memory[0][31:0]);$finish;end
endmodule
`default_nettype wire
