`default_nettype none
module core_assertions(input logic clk,input logic rst_n,input logic[31:0]x0);
`ifdef ENABLE_SVA
    assert property(@(posedge clk) disable iff(!rst_n) x0==0);
`endif
endmodule
`default_nettype wire
