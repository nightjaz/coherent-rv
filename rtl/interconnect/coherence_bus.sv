`default_nettype none
module coherence_bus #(parameter integer LINE_SIZE=32)(
    input logic clk, input logic rst_n,
    input logic request0, input logic [1:0] command0, input logic [31:0] address0,
    input logic [LINE_SIZE*8-1:0] write_line0,
    output logic grant0, output logic ready0, output logic shared0,
    output logic [LINE_SIZE*8-1:0] read_line0,
    input logic request1, input logic [1:0] command1, input logic [31:0] address1,
    input logic [LINE_SIZE*8-1:0] write_line1,
    output logic grant1, output logic ready1, output logic shared1,
    output logic [LINE_SIZE*8-1:0] read_line1,
    output logic snoop_valid0, output logic [1:0] snoop_command0, output logic [31:0] snoop_address0,
    input logic snoop_hit0, input logic snoop_supply0, input logic [LINE_SIZE*8-1:0] snoop_line0,
    output logic snoop_valid1, output logic [1:0] snoop_command1, output logic [31:0] snoop_address1,
    input logic snoop_hit1, input logic snoop_supply1, input logic [LINE_SIZE*8-1:0] snoop_line1,
    output logic memory_read, output logic memory_write, output logic [31:0] memory_address,
    output logic [LINE_SIZE*8-1:0] memory_write_line,
    input logic [LINE_SIZE*8-1:0] memory_read_line, input logic memory_ready,
    output logic [63:0] bus_rd_count, output logic [63:0] bus_rdx_count,
    output logic [63:0] bus_upgr_count
);
    localparam logic [1:0] BUS_RD=0, BUS_RDX=1, BUS_UPGR=2, BUS_WB=3;
    logic [1:0] selected_command; logic [31:0] selected_address;
    logic [LINE_SIZE*8-1:0] selected_write_line;
    logic peer_hit, peer_supply; logic [LINE_SIZE*8-1:0] peer_line;
    logic raw_grant0,raw_grant1,active,owner;
    logic [1:0] active_command;logic [31:0] active_address;
    logic [LINE_SIZE*8-1:0] active_write_line;
    logic active_peer_hit,active_peer_supply;
    logic [LINE_SIZE*8-1:0]active_peer_line;
    bus_arbiter u_arbiter(.clk,.rst_n,.request0(request0&&!active),.request1(request1&&!active),.grant0(raw_grant0),.grant1(raw_grant1));
    always_comb begin
        grant0=active?!owner:raw_grant0;grant1=active?owner:raw_grant1;
        selected_command=active?active_command:(raw_grant0?command0:command1);
        selected_address=active?active_address:(raw_grant0?address0:address1);
        selected_write_line=active?active_write_line:(raw_grant0?write_line0:write_line1);
        peer_hit=active?active_peer_hit:(grant0?snoop_hit1:snoop_hit0);
        peer_supply=active?active_peer_supply:(grant0?snoop_supply1:snoop_supply0);
        peer_line=active?active_peer_line:(grant0?snoop_line1:snoop_line0);
        snoop_valid0=!active&&grant1&&selected_command!=BUS_WB;snoop_command0=selected_command;snoop_address0=selected_address;
        snoop_valid1=!active&&grant0&&selected_command!=BUS_WB;snoop_command1=selected_command;snoop_address1=selected_address;
        memory_address=selected_address; memory_write_line=selected_write_line;
        memory_read=(grant0||grant1) && (selected_command==BUS_RD || selected_command==BUS_RDX);
        memory_write=(grant0||grant1) && (selected_command==BUS_WB ||
            (selected_command==BUS_RD && peer_supply));
        if(selected_command==BUS_RD && peer_supply) memory_write_line=peer_line;
        ready0=grant0 && (selected_command==BUS_UPGR || memory_ready);
        ready1=grant1 && (selected_command==BUS_UPGR || memory_ready);
        shared0=grant0 && peer_hit; shared1=grant1 && peer_hit;
        read_line0=peer_supply?peer_line:memory_read_line;
        read_line1=peer_supply?peer_line:memory_read_line;
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            active<=0;owner<=0;active_command<=0;active_address<=0;active_write_line<='0;
            active_peer_hit<=0;active_peer_supply<=0;active_peer_line<='0;
            bus_rd_count<=0; bus_rdx_count<=0; bus_upgr_count<=0;
        end else begin
            if(!active&&(raw_grant0||raw_grant1)&&!(ready0||ready1))begin
                active<=1;owner<=raw_grant1;active_command<=selected_command;
                active_address<=selected_address;active_write_line<=selected_write_line;
                active_peer_hit<=peer_hit;active_peer_supply<=peer_supply;active_peer_line<=peer_line;
            end else if(active&&(ready0||ready1))active<=0;
            if((ready0||ready1)) case(selected_command)
                BUS_RD: bus_rd_count<=bus_rd_count+1;
                BUS_RDX: bus_rdx_count<=bus_rdx_count+1;
                BUS_UPGR: bus_upgr_count<=bus_upgr_count+1;
                default: ;
            endcase
        end
    end
endmodule
`default_nettype wire
