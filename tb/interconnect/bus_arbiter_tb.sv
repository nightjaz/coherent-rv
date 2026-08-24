`timescale 1ns/1ps
`default_nettype none
module bus_arbiter_tb;
 logic clk=0,rst_n=0,r0,r1,g0,g1;integer i,c0,c1;always #5 clk=~clk;
 bus_arbiter dut(.clk,.rst_n,.request0(r0),.request1(r1),.grant0(g0),.grant1(g1));
 initial begin r0=0;r1=0;c0=0;c1=0;repeat(2)@(posedge clk);rst_n<=1;@(negedge clk);r0=1;r1=1;
  for(i=0;i<100;i=i+1)begin @(posedge clk);if(g0)c0=c0+1;if(g1)c1=c1+1;if(g0&&g1)$fatal(1,"dual grant");end
  if(c0!=50||c1!=50)$fatal(1,"unfair grants %0d/%0d",c0,c1);
  $display("PASS arbiter sustained fairness grants=%0d/%0d",c0,c1);$finish;end
endmodule
`default_nettype wire
