`default_nettype none
module dcache #(
    parameter integer CACHE_SIZE=1024,
    parameter integer LINE_SIZE=32
) (
    input logic clk, input logic rst_n,
    input logic cpu_request, input logic cpu_write,
    input logic [31:0] cpu_address, input logic [31:0] cpu_write_data,
    input logic [3:0] cpu_byte_enable,
    output logic [31:0] cpu_read_data, output logic cpu_ready,
    output logic bus_request, output logic [1:0] bus_command,
    output logic [31:0] bus_address,
    output logic [LINE_SIZE*8-1:0] bus_write_line,
    input logic bus_grant, input logic bus_ready, input logic bus_shared,
    input logic [LINE_SIZE*8-1:0] bus_read_line,
    input logic snoop_valid, input logic [1:0] snoop_command,
    input logic [31:0] snoop_address,
    output logic snoop_hit, output logic snoop_supply,
    output logic [LINE_SIZE*8-1:0] snoop_line,
    output logic [63:0] hit_count, output logic [63:0] miss_count,
    output logic [63:0] writeback_count, output logic [63:0] invalidation_count,
    output logic [63:0] mesi_m_cycles,output logic [63:0] mesi_e_cycles,
    output logic [63:0] mesi_s_cycles,output logic [63:0] mesi_i_cycles
);
    localparam integer NUM_SETS=CACHE_SIZE/LINE_SIZE;
    localparam integer OFFSET_BITS=$clog2(LINE_SIZE);
    localparam integer INDEX_BITS=$clog2(NUM_SETS);
    localparam integer TAG_BITS=32-OFFSET_BITS-INDEX_BITS;
`ifndef SYNTHESIS
    initial begin
        if(CACHE_SIZE<LINE_SIZE || CACHE_SIZE%LINE_SIZE!=0 || (CACHE_SIZE&(CACHE_SIZE-1))!=0)
            $fatal(1,"CACHE_SIZE must be a power of two and a multiple of LINE_SIZE");
        if(LINE_SIZE<4 || (LINE_SIZE&(LINE_SIZE-1))!=0)
            $fatal(1,"LINE_SIZE must be a power of two >= 4");
    end
`endif
    localparam logic [1:0] MESI_I=0, MESI_S=1, MESI_E=2, MESI_M=3;
    localparam logic [1:0] BUS_RD=0, BUS_RDX=1, BUS_UPGR=2, BUS_WB=3;
    typedef enum logic [1:0] {IDLE, WRITEBACK, ACQUIRE} control_state_t;
    control_state_t control_state;
    logic [TAG_BITS-1:0] tags[0:NUM_SETS-1];
    logic [1:0] states[0:NUM_SETS-1];
    logic [LINE_SIZE*8-1:0] data[0:NUM_SETS-1];
    logic pending_write; logic [31:0] pending_address, pending_write_data;
    logic [3:0] pending_byte_enable; logic [1:0] pending_command;
    logic [TAG_BITS-1:0] victim_tag;
    logic [INDEX_BITS-1:0] pending_index;
    logic cpu_hit; logic [INDEX_BITS-1:0] cpu_index, snoop_index;
    logic [TAG_BITS-1:0] cpu_tag, snoop_tag;
    logic [OFFSET_BITS-1:2] cpu_word, pending_word;
    integer i,occupancy_index;logic[63:0]count_m,count_e,count_s,count_i;
    logic[NUM_SETS-1:0]m_vector,e_vector,s_vector,i_vector;
    logic completing_local_write;integer snoop_byte;
    logic [1:0] snoop_next_state,unused_local_command;
    logic unused_local_request,unused_snoop_invalidate;
    genvar state_index;
    generate for(state_index=0;state_index<NUM_SETS;state_index=state_index+1)begin: occupancy_vector
        assign m_vector[state_index]=states[state_index]==MESI_M;
        assign e_vector[state_index]=states[state_index]==MESI_E;
        assign s_vector[state_index]=states[state_index]==MESI_S;
        assign i_vector[state_index]=states[state_index]==MESI_I;
    end endgenerate

    assign cpu_index=cpu_address[OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS];
    assign cpu_tag=cpu_address[31:OFFSET_BITS+INDEX_BITS];
    assign cpu_word=cpu_address[OFFSET_BITS-1:2];
    assign cpu_hit=states[cpu_index]!=MESI_I && tags[cpu_index]==cpu_tag;
    assign pending_word=pending_address[OFFSET_BITS-1:2];
    assign snoop_index=snoop_address[OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS];
    assign snoop_tag=snoop_address[31:OFFSET_BITS+INDEX_BITS];
    mesi_controller u_mesi_controller(.current_state(states[snoop_index]),.local_read(1'b0),.local_write(1'b0),.bus_shared(1'b0),
        .snoop_valid(snoop_valid&&tags[snoop_index]==snoop_tag),.snoop_command,
        .next_state(snoop_next_state),.local_bus_command(unused_local_command),.local_bus_request(unused_local_request),
        .snoop_hit,.snoop_supply,.snoop_invalidate(unused_snoop_invalidate));
    assign completing_local_write=control_state==IDLE&&cpu_request&&cpu_write&&cpu_hit&&cpu_index==snoop_index&&snoop_valid;
    always_comb begin
        snoop_line=data[snoop_index];
        snoop_byte=0;
        if(completing_local_write)for(snoop_byte=0;snoop_byte<4;snoop_byte=snoop_byte+1)
            if(cpu_byte_enable[snoop_byte])snoop_line[cpu_word*32+snoop_byte*8 +:8]=cpu_write_data[snoop_byte*8 +:8];
    end
    always_comb begin
`ifndef LEGACY_COUNTONES_OCCUPANCY
        count_m=0;count_e=0;count_s=0;count_i=0;
        for(occupancy_index=0;occupancy_index<NUM_SETS;occupancy_index=occupancy_index+1)begin
            count_m=count_m+(states[occupancy_index]==MESI_M);
            count_e=count_e+(states[occupancy_index]==MESI_E);
            count_s=count_s+(states[occupancy_index]==MESI_S);
            count_i=count_i+(states[occupancy_index]==MESI_I);
        end
`else
        count_m=$countones(m_vector);count_e=$countones(e_vector);
        count_s=$countones(s_vector);count_i=$countones(i_vector);
`endif
    end

    always_comb begin
        cpu_ready=0;cpu_read_data=0;
        if(control_state==IDLE&&cpu_request&&cpu_hit&&(!cpu_write||states[cpu_index]!=MESI_S))begin
            cpu_ready=1;cpu_read_data=data[cpu_index][cpu_word*32 +:32];
        end else if(control_state==ACQUIRE&&bus_grant&&bus_ready)begin
            cpu_ready=1;cpu_read_data=bus_read_line[pending_word*32 +:32];
        end
    end

    always_comb begin
        bus_request=0; bus_command=pending_command; bus_address={pending_address[31:OFFSET_BITS],{OFFSET_BITS{1'b0}}};
        bus_write_line=data[pending_index];
        if(control_state==WRITEBACK) begin
            bus_request=1; bus_command=BUS_WB;
            bus_address={{victim_tag},{pending_index},{OFFSET_BITS{1'b0}}};
        end else if(control_state==ACQUIRE) bus_request=1;
    end

    task automatic merge_pending;
        integer byte_number; integer bit_base;
        begin
            bit_base=pending_word*32;
            for(byte_number=0;byte_number<4;byte_number=byte_number+1)
                if(pending_byte_enable[byte_number])
                    data[pending_index][bit_base+byte_number*8 +: 8] <= pending_write_data[byte_number*8 +: 8];
        end
    endtask

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            control_state<=IDLE;
            hit_count<=0; miss_count<=0; writeback_count<=0; invalidation_count<=0;
            mesi_m_cycles<=0;mesi_e_cycles<=0;mesi_s_cycles<=0;mesi_i_cycles<=0;
            pending_write<=0; pending_address<=0; pending_write_data<=0; pending_byte_enable<=0;
            pending_command<=BUS_RD; victim_tag<=0; pending_index<=0;
            for(i=0;i<NUM_SETS;i=i+1) begin tags[i]<='0; states[i]<=MESI_I; data[i]<='0; end
        end else begin
            mesi_m_cycles<=mesi_m_cycles+count_m;mesi_e_cycles<=mesi_e_cycles+count_e;
            mesi_s_cycles<=mesi_s_cycles+count_s;mesi_i_cycles<=mesi_i_cycles+count_i;
            if(control_state==IDLE && cpu_request) begin
                if(cpu_hit) begin
                    hit_count<=hit_count+1;
                    if(!cpu_write) begin
                        ;
                    end else if(states[cpu_index]==MESI_S) begin
                        pending_write<=1; pending_address<=cpu_address; pending_write_data<=cpu_write_data;
                        pending_byte_enable<=cpu_byte_enable; pending_index<=cpu_index;
                        pending_command<=BUS_UPGR; control_state<=ACQUIRE;
                    end else begin
                        pending_address<=cpu_address; pending_write_data<=cpu_write_data;
                        pending_byte_enable<=cpu_byte_enable; pending_index<=cpu_index;
                        for(i=0;i<4;i=i+1) if(cpu_byte_enable[i])
                            data[cpu_index][cpu_word*32+i*8 +:8]<=cpu_write_data[i*8 +:8];
                        states[cpu_index]<=MESI_M;
                    end
                end else begin
                    miss_count<=miss_count+1; pending_write<=cpu_write; pending_address<=cpu_address;
                    pending_write_data<=cpu_write_data; pending_byte_enable<=cpu_byte_enable; pending_index<=cpu_index;
                    pending_command<=cpu_write ? BUS_RDX : BUS_RD; victim_tag<=tags[cpu_index];
                    if(states[cpu_index]==MESI_M) begin control_state<=WRITEBACK; writeback_count<=writeback_count+1; end
                    else begin states[cpu_index]<=MESI_I; control_state<=ACQUIRE; end
                end
            end else if(control_state==WRITEBACK && bus_grant && bus_ready) begin
                states[pending_index]<=MESI_I; control_state<=ACQUIRE;
            end else if(control_state==ACQUIRE && bus_grant && bus_ready) begin
                tags[pending_index]<=pending_address[31:OFFSET_BITS+INDEX_BITS];
                if(pending_command!=BUS_UPGR) data[pending_index]<=bus_read_line;
                if(pending_write) begin
                    merge_pending(); states[pending_index]<=MESI_M;
                end else begin
                    states[pending_index]<=bus_shared ? MESI_S : MESI_E;
                    ;
                end
                control_state<=IDLE;
            end

            if(snoop_hit) begin
                states[snoop_index]<=snoop_next_state;
                if(unused_snoop_invalidate)invalidation_count<=invalidation_count+1;
                if(control_state==ACQUIRE && pending_command==BUS_UPGR &&
                   pending_index==snoop_index && tags[snoop_index]==snoop_tag &&
                   (snoop_command==BUS_RDX || snoop_command==BUS_UPGR))
                    pending_command<=BUS_RDX;
            end
        end
    end
endmodule
`default_nettype wire
