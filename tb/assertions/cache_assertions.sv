`default_nettype none
module cache_assertions(input logic clk,input logic rst_n,input logic cpu_ready,input logic cpu_request,
 input logic[31:0]cpu_address,input logic bus_ready,input logic bus_grant,input logic bus_request,
 input logic[31:0]bus_address);
`ifdef ENABLE_SVA
 logic cpu_outstanding,bus_outstanding;logic[31:0]cpu_pending_address,bus_pending_address;
 always_ff @(posedge clk or negedge rst_n)begin
  if(!rst_n)begin cpu_outstanding<=0;bus_outstanding<=0;cpu_pending_address<=0;bus_pending_address<=0;end
  else begin
   if(cpu_request&&!cpu_ready&&!cpu_outstanding)begin cpu_outstanding<=1;cpu_pending_address<=cpu_address;end
   if(cpu_ready)cpu_outstanding<=0;
   if(bus_request&&!bus_ready&&!bus_outstanding)begin bus_outstanding<=1;bus_pending_address<=bus_address;end
   if(bus_ready)bus_outstanding<=0;
  end
 end
 assert property(@(posedge clk) disable iff(!rst_n) cpu_ready |-> cpu_request);
 assert property(@(posedge clk) disable iff(!rst_n) bus_ready |-> (bus_grant&&bus_request));
 assert property(@(posedge clk) disable iff(!rst_n) cpu_outstanding |-> cpu_request&&cpu_address==cpu_pending_address);
 assert property(@(posedge clk) disable iff(!rst_n) bus_outstanding |-> bus_request&&bus_address==bus_pending_address);
 assert property(@(posedge clk) disable iff(!rst_n) cpu_ready&&cpu_outstanding |-> cpu_address==cpu_pending_address);
 assert property(@(posedge clk) disable iff(!rst_n) bus_ready&&bus_outstanding |-> bus_address==bus_pending_address);
`endif
endmodule
`default_nettype wire
