`default_nettype none
module memory_stage(input logic request, input logic ready, output logic stall);
    assign stall=request && !ready;
endmodule
`default_nettype wire
