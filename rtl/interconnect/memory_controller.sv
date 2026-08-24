`default_nettype none
module memory_controller #(parameter integer LINE_BYTES=32)(
    input logic request, input logic write,
    output logic memory_read, output logic memory_write
);
    assign memory_read=request && !write;
    assign memory_write=request && write;
endmodule
`default_nettype wire
