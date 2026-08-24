`default_nettype none
module simple_memory #(
    parameter integer ADDRESS_WIDTH=16,
    parameter integer LINE_BYTES=32
) (
    input logic clk,
    input logic read_enable,
    input logic write_enable,
    input logic [31:0] address,
    input logic [LINE_BYTES*8-1:0] write_line,
    output logic [LINE_BYTES*8-1:0] read_line,
    output logic ready
);
    localparam integer DEPTH=(1<<ADDRESS_WIDTH)/LINE_BYTES;
    localparam integer LINE_LSB=$clog2(LINE_BYTES);
    logic [LINE_BYTES*8-1:0] lines [0:DEPTH-1];
    integer i;
    initial begin
        for(i=0;i<DEPTH;i=i+1) lines[i]='0;
    end
    assign read_line=lines[address[ADDRESS_WIDTH-1:LINE_LSB]];
    assign ready=read_enable || write_enable;
    always_ff @(posedge clk) if(write_enable) lines[address[ADDRESS_WIDTH-1:LINE_LSB]]<=write_line;
endmodule
`default_nettype wire
