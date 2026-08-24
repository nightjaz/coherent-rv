`default_nettype none
module load_store_unit(
    input logic[31:0]address,input logic[2:0]funct3,
    input logic[31:0]store_value,input logic[31:0]memory_read_data,
    output logic[31:0]load_value,output logic[31:0]store_aligned,
    output logic[3:0]byte_enable
);
    logic[31:0]shifted;
    always_comb begin
        shifted=memory_read_data>>(8*address[1:0]);
        case(funct3)
            3'b000:load_value={{24{shifted[7]}},shifted[7:0]};
            3'b001:load_value={{16{shifted[15]}},shifted[15:0]};
            3'b100:load_value={24'b0,shifted[7:0]};
            3'b101:load_value={16'b0,shifted[15:0]};
            default:load_value=memory_read_data;
        endcase
        byte_enable=0;store_aligned=0;
        case(funct3)
            3'b000:begin byte_enable=4'b0001<<address[1:0];store_aligned=store_value<<(8*address[1:0]);end
            3'b001:begin byte_enable=address[1]?4'b1100:4'b0011;store_aligned=store_value<<(16*address[1]);end
            default:begin byte_enable=4'b1111;store_aligned=store_value;end
        endcase
    end
endmodule
`default_nettype wire
