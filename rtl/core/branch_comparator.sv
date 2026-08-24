`default_nettype none
module branch_comparator(
    input logic[31:0]a,input logic[31:0]b,input logic[2:0]operation,
    output logic taken
);
    always_comb case(operation)
        3'b000:taken=a==b;
        3'b001:taken=a!=b;
        3'b100:taken=$signed(a)<$signed(b);
        3'b101:taken=$signed(a)>=$signed(b);
        3'b110:taken=a<b;
        3'b111:taken=a>=b;
        default:taken=0;
    endcase
endmodule
`default_nettype wire
