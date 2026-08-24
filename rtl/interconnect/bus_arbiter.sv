`default_nettype none
module bus_arbiter (
    input logic clk, input logic rst_n,
    input logic request0, input logic request1,
    output logic grant0, output logic grant1
);
    logic last_grant;
    always_comb begin
        grant0=0; grant1=0;
        case ({request1,request0})
            2'b01: grant0=1;
            2'b10: grant1=1;
            2'b11: if (last_grant) grant0=1; else grant1=1;
            default: ;
        endcase
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) last_grant<=1'b1;
        else if(grant0) last_grant<=1'b0;
        else if(grant1) last_grant<=1'b1;
    end
endmodule
`default_nettype wire
