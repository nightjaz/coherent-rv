`default_nettype none
(* blackbox *) module simple_memory #(
  parameter integer ADDRESS_WIDTH=16,parameter integer LINE_BYTES=32
)(input logic clk,input logic read_enable,input logic write_enable,input logic[31:0]address,
  input logic[LINE_BYTES*8-1:0]write_line,output logic[LINE_BYTES*8-1:0]read_line,output logic ready);
endmodule
`default_nettype wire
