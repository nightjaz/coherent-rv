`default_nettype none
module coherence_assertions(input logic clk,input logic rst_n,input logic grant0,input logic grant1,
    input logic[1:0]state0,input logic[1:0]state1,input logic tags_equal);
`ifdef ENABLE_SVA
    assert property(@(posedge clk) disable iff(!rst_n) !(grant0&&grant1));
    assert property(@(posedge clk) disable iff(!rst_n) !(tags_equal&&state0==3&&state1==3));
    assert property(@(posedge clk) disable iff(!rst_n) (tags_equal&&state0==3|->state1==0));
    assert property(@(posedge clk) disable iff(!rst_n) (tags_equal&&state1==3|->state0==0));
    assert property(@(posedge clk) disable iff(!rst_n) (tags_equal&&state0==2|->state1==0));
    assert property(@(posedge clk) disable iff(!rst_n) (tags_equal&&state1==2|->state0==0));
`endif
endmodule
`default_nettype wire
