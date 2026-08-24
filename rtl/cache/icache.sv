`default_nettype none
module icache #(
    parameter integer CACHE_SIZE=1024,
    parameter integer LINE_SIZE=32
)(
    input logic clk,input logic rst_n,
    input logic cpu_request,input logic [31:0] cpu_address,
    output logic [31:0] cpu_read_data,output logic cpu_ready,
    output logic memory_request,output logic [31:0] memory_address,
    input logic [LINE_SIZE*8-1:0] memory_read_line,input logic memory_ready,
    output logic [63:0] hit_count,output logic [63:0] miss_count
);
    localparam integer NUM_SETS=CACHE_SIZE/LINE_SIZE, OFFSET_BITS=$clog2(LINE_SIZE), INDEX_BITS=$clog2(NUM_SETS);
    localparam integer TAG_BITS=32-OFFSET_BITS-INDEX_BITS;
`ifndef SYNTHESIS
    initial begin
        if(CACHE_SIZE<LINE_SIZE || CACHE_SIZE%LINE_SIZE!=0 || (CACHE_SIZE&(CACHE_SIZE-1))!=0)
            $fatal(1,"CACHE_SIZE must be a power of two and a multiple of LINE_SIZE");
        if(LINE_SIZE<4 || (LINE_SIZE&(LINE_SIZE-1))!=0)
            $fatal(1,"LINE_SIZE must be a power of two >= 4");
    end
`endif
    logic valid[0:NUM_SETS-1]; logic [TAG_BITS-1:0] tags[0:NUM_SETS-1];
    logic [LINE_SIZE*8-1:0] data[0:NUM_SETS-1];
    logic waiting; logic [31:0] pending_address;
    wire [INDEX_BITS-1:0] cpu_index=cpu_address[OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS];
    wire [TAG_BITS-1:0] cpu_tag=cpu_address[31:OFFSET_BITS+INDEX_BITS];
    wire [OFFSET_BITS-1:2] cpu_word=cpu_address[OFFSET_BITS-1:2];
    wire hit=valid[cpu_index]&&tags[cpu_index]==cpu_tag;
    wire [INDEX_BITS-1:0] pending_index=pending_address[OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS];
    wire [OFFSET_BITS-1:2] pending_word=pending_address[OFFSET_BITS-1:2];
    integer i;
    assign memory_request=waiting;
    assign memory_address={pending_address[31:OFFSET_BITS],{OFFSET_BITS{1'b0}}};
    always_comb begin
        cpu_ready=0;cpu_read_data=0;
        if(!waiting&&cpu_request&&hit)begin cpu_ready=1;cpu_read_data=data[cpu_index][cpu_word*32 +:32];end
        else if(waiting&&memory_ready&&cpu_address==pending_address)begin cpu_ready=1;cpu_read_data=memory_read_line[pending_word*32 +:32];end
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin waiting<=0;hit_count<=0;miss_count<=0;
            for(i=0;i<NUM_SETS;i=i+1) begin valid[i]<=0;tags[i]<='0;data[i]<='0;end
        end else begin
            if(!waiting&&cpu_request) begin
                if(hit) begin hit_count<=hit_count+1;end
                else begin waiting<=1;pending_address<=cpu_address;miss_count<=miss_count+1;end
            end else if(waiting&&memory_ready) begin
                data[pending_index]<=memory_read_line;tags[pending_index]<=pending_address[31:OFFSET_BITS+INDEX_BITS];valid[pending_index]<=1;
                waiting<=0;
            end
        end
    end
endmodule
`default_nettype wire
