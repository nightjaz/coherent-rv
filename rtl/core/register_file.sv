`default_nettype none
module register_file #(
    parameter bit WRITE_THROUGH=1'b1
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [4:0]  rs1_addr,
    input  logic [4:0]  rs2_addr,
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data,
    input  logic        write_enable,
    input  logic [4:0]  write_addr,
    input  logic [31:0] write_data
);
    logic [31:0] registers [0:31];
    integer i;
    assign rs1_data = (rs1_addr == 0) ? 32'b0 :
        ((WRITE_THROUGH && write_enable && write_addr == rs1_addr) ? write_data : registers[rs1_addr]);
    assign rs2_data = (rs2_addr == 0) ? 32'b0 :
        ((WRITE_THROUGH && write_enable && write_addr == rs2_addr) ? write_data : registers[rs2_addr]);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) registers[i] <= 32'b0;
        end else begin
            if (write_enable && write_addr != 0) registers[write_addr] <= write_data;
            registers[0] <= 32'b0;
        end
    end
endmodule
`default_nettype wire
